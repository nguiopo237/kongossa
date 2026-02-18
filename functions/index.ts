/**
 * Import function triggers from their respective submodules:
 */
import { onCall } from "firebase-functions/v2/https";
import { onRequest } from "firebase-functions/v2/https";  // ← Ajoutez cette ligne
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
 * Note: Typage explicite des paramètres req et res
 */
export const healthCheck = onRequest((
    req: any,  // Vous pouvez utiliser 'any' ou importer Request de express
    res: any   // Vous pouvez utiliser 'any' ou importer Response de express
) => {
    res.status(200).json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        functions: ['sendChatNotification']
    });
});