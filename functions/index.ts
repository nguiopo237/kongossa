/**
 * Import function triggers from their respective submodules:
 */
import { onCall } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onRequest } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";
import * as logger from "firebase-functions/logger";
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Configuration globale (optionnelle)
setGlobalOptions({
    maxInstances: 10,
    region: 'europe-west1' // ou 'us-central1' selon votre préférence
});

// Interface pour les données de notification
interface NotificationData {
    receiverId: string;
    message: string;
    senderName: string;
    senderId: string;
    conversationId?: string;
}

/**
 * Fonction pour envoyer une notification de chat
 */
export const sendChatNotification = onCall<NotificationData>(async (request) => {
    // Vérifier que l'utilisateur est authentifié
    if (!request.auth) {
        throw new Error('Vous devez être connecté pour envoyer une notification');
    }

    const { receiverId, message, senderName, senderId, conversationId } = request.data;

    logger.info('Tentative d\'envoi de notification', {
        receiverId,
        senderId,
        messageLength: message?.length
    });

    try {
        // Récupérer le document de l'utilisateur destinataire
        const userDoc = await admin.firestore()
            .collection('user')
            .doc(receiverId)
            .get();

        if (!userDoc.exists) {
            logger.error('Utilisateur non trouvé', { receiverId });
            throw new Error(`Utilisateur ${receiverId} non trouvé`);
        }

        const userData = userDoc.data();
        const fcmToken = userData?.fcmToken;

        if (!fcmToken) {
            logger.log('Pas de token FCM pour', receiverId);
            return {
                success: false,
                reason: 'no_token',
                message: 'Utilisateur non disponible pour les notifications'
            };
        }

        // Préparer la notification
        const payload = {
            token: fcmToken,
            notification: {
                title: senderName || 'Nouveau message',
                body: message,
            },
            data: {
                senderId: senderId,
                senderName: senderName,
                type: 'chat',
                conversationId: conversationId || '',
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            },
            android: {
                priority: 'high' as const,
                notification: {
                    sound: 'default',
                    channelId: 'chat_messages'
                }
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default'
                    }
                }
            }
        };

        // Envoyer la notification
        const response = await admin.messaging().send(payload);

        logger.info('✅ Notification envoyée avec succès', {
            messageId: response,
            receiverId
        });

        return {
            success: true,
            messageId: response,
            receiverId
        };

    } catch (error) {
        logger.error('Erreur lors de l\'envoi de la notification:', error);

        // Gérer les erreurs spécifiques
        if (error instanceof Error) {
            if (error.message.includes('registration-token-not-registered')) {
                return {
                    success: false,
                    reason: 'invalid_token',
                    message: 'Token FCM invalide ou expiré'
                };
            }
            throw new Error(`Erreur d'envoi: ${error.message}`);
        }

        throw new Error('Erreur inconnue lors de l\'envoi de la notification');
    }
});

/**
 * Fonction utilitaire pour vérifier le statut de la fonction
 */
export const healthCheck = onRequest((
    req: any,
    res: any
) => {
    res.status(200).json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        functions: ['sendChatNotification', 'onLiveCreated']
    });
});

/**
 * Trigger Firestore – Notification push aux followers quand un live démarre.
 */
export const onLiveCreated = onDocumentCreated("lives/{liveId}", async (event) => {
    const snap = event.data;
    if (!snap) {
        logger.warn("onLiveCreated: snap is null");
        return;
    }

    const liveData = snap.data();
    const hostId = liveData.hostId as string;
    const hostName = liveData.hostName as string;
    const liveTitle = liveData.title as string;
    const liveId = snap.id;

    logger.info(`🔴 Live démarré par ${hostName} (${hostId}): ${liveTitle}`);

    try {
        // 1. Trouver le doc Firestore de l'hôte via googleId
        const hostQuery = await admin.firestore()
            .collection('user')
            .where('googleId', '==', hostId)
            .limit(1)
            .get();

        if (hostQuery.empty) {
            logger.warn(`Hôte ${hostId} introuvable dans Firestore`);
            return;
        }

        const hostDoc = hostQuery.docs[0];
        const hostData = hostDoc.data();
        const followerIds: string[] = (hostData.allfollow as string[]) || [];

        if (followerIds.length === 0) {
            logger.info(`Aucun follower pour ${hostName} — pas de notification`);
            return;
        }

        logger.info(`📣 ${followerIds.length} follower(s) à notifier pour ${hostName}`);

        // 2. Récupérer les tokens FCM de tous les followers en une requête
        // On récupère les docs par lots de 10 (limite Firestore `in`)
        const BATCH_SIZE = 10;
        const tokens: string[] = [];

        for (let i = 0; i < followerIds.length; i += BATCH_SIZE) {
            const batch = followerIds.slice(i, i + BATCH_SIZE);
            const followerDocs = await admin.firestore()
                .collection('user')
                .where(admin.firestore.FieldPath.documentId(), 'in', batch)
                .get();

            followerDocs.forEach((doc) => {
                const data = doc.data();
                const token = data.fcmToken as string | undefined;
                if (token && token.trim().length > 0) {
                    tokens.push(token);
                }
            });
        }

        if (tokens.length === 0) {
            logger.info(`Aucun token FCM disponible pour les followers de ${hostName}`);
            return;
        }

        // 3. Envoyer les notifications via FCM
        const payload = {
            notification: {
                title: `🔴 ${hostName} est en live !`,
                body: liveTitle || 'Rejoignez le live maintenant',
            },
            data: {
                type: 'live',
                liveId: liveId,
                hostId: hostId,
                hostName: hostName,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
                priority: 'high' as const,
                notification: {
                    sound: 'default',
                    channelId: 'live_notifications',
                    color: '#D4AF37',
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                    },
                },
            },
        };

        // Envoyer à chaque token individuellement + logguer les résultats
        let successCount = 0;
        let failCount = 0;

        for (const token of tokens) {
            try {
                const messageId = await admin.messaging().send({
                    ...payload,
                    token,
                });
                logger.info(`✅ Notification FCM envoyée: ${messageId}`);
                successCount++;
            } catch (error) {
                if (error instanceof Error) {
                    if (error.message.includes('registration-token-not-registered')) {
                        logger.warn(`Token FCM invalide (supprimé): ${token.slice(0, 20)}...`);
                    } else {
                        logger.error(`Erreur FCM: ${error.message}`);
                    }
                }
                failCount++;
            }
        }

        logger.info(`📊 Résultat: ${successCount} envoyée(s), ${failCount} échec(s)`);

    } catch (error) {
        logger.error('❌ Erreur onLiveCreated:', error);
    }
});

