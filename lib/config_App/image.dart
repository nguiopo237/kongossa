
import 'environnement.dart';

class Consticon{

  static String search = 'assets/svg/search.svg';
  static String notification = 'assets/svg/notification.svg';
  static String profil = 'assets/svg/profil.svg';
  static String coverpage = 'assets/svg/Cover.svg';
  static String global = 'assets/svg/globeall.svg';
  static String collaborate = 'assets/svg/mycolaborator.svg';
  static String like = 'assets/svg/like.svg';
  static String sms = 'assets/svg/sms.svg';
  static String tchat = 'assets/svg/tchat.svg';
  static String love = 'assets/svg/love.svg';
  static String sharepost = 'assets/svg/share.svg';
  static String share = 'assets/svg/share.svg';
  static String sharee = 'assets/svg/sharee.svg';
  static const String imagesOrange = 'assets/svg/orange.svg';
  static String delete = 'assets/svg/delete.svg';
  static String signaler = 'assets/svg/signaler.svg';
  static String edit = 'assets/svg/edit.svg';
  static String cloud = 'assets/svg/cloud.svg';
  static String video = 'assets/svg/video.svg';
  static String television = 'assets/svg/television.svg';
  static String eye = 'assets/svg/eye.svg';
  static String link = 'assets/svg/lien.svg';
  static String add = 'assets/svg/adds.svg';
  static String folder = 'assets/svg/dossier.svg';
  static String file = 'assets/svg/file.svg';
  static String backimage = 'assets/svg/form.svg';
  static String signal = 'assets/svg/signal.svg';
  static const String svgin = 'assets/svg/in.svg';
  static const String cotisation = 'assets/svg/circle-stack.svg';
  static const String flash = 'assets/svg/flash.svg';
  static const String wallet = 'assets/svg/wallet.svg';
  static const String epargne = 'assets/svg/epargne.svg';
  static const String communaute = 'assets/svg/user-group.svg';

  static const String setting = 'assets/svg/setting.svg';
  static const String searchcontact = 'assets/svg/Search-Contacts.svg';
  static const String svgClient = 'assets/svg/client.svg';
  static const String svgQuestion = 'assets/svg/question.svg';
  static const String svgScan = 'assets/svg/scan.svg';
  static const String svgDisconnect = 'assets/svg/disconnect.svg';
  static const String svgWinmoney = 'assets/svg/winmoney.svg';
  static const String svgInfo = 'assets/svg/info.svg';
  static const String svgBuy = 'assets/svg/buy.svg';
  static const String svgLanguage = 'assets/svg/language.svg';
  static const String svgTerme = 'assets/svg/terme.svg';
  static const String svgPolitic = 'assets/svg/politic.svg';
  static const String svgCheck = 'assets/svg/check.svg';
  static const String svgPassword = 'assets/svg/password.svg';
  static const String svgFrame = 'assets/svg/frame.svg';


  static String successdefault = 'assets/svg/checkcircle.svg';
  static String testimage = 'assets/svg/testimage.svg';
  static const String searchcontacts= 'assets/images/SearchContacts.png';
  static const String orange= 'assets/images/oms.png';
  static const String mf= 'assets/images/mf.png';
  static const String mc= 'assets/images/mc.png';
  static const String flashs= 'assets/images/flash.png';
  static const String login= 'assets/images/login.png';
  static const String pay= 'assets/images/pay.png';
  static const String imageprofil= 'assets/images/profil.png';
  static const String eu= 'assets/images/eu.png';
  static const String cochon= 'assets/images/cochon.png';
  static const String person= 'assets/images/person.png';
  static const String logo= 'assets/logo/logo.png';
  static const String background= 'assets/Backgrounds/motif_g.jpeg';
  static const String background2= 'assets/Backgrounds/pagne.jpeg';

  Future<String> getMedia({String ?item}) async {
    String url  = "${Env.baseurlImg}/${item}";
    String urlvideo  = "${Env.baseurlvideo}/${item}";
    return  item!.contains("image")? url:urlvideo;
  }



}