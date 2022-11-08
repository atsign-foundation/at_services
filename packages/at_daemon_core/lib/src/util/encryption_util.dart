import 'package:at_commons/at_commons.dart';
import 'package:at_utils/at_logger.dart';
import 'package:encrypt/encrypt.dart';
import 'package:crypton/crypton.dart';

class EncryptionUtil {
  static final _logger = AtSignLogger('EncryptionUtil');

  static RSAKeypair generateRSAKeys() {
    return RSAKeypair.fromRandom(keySize: 4096);
  }

  static String generateAESKey() {
    var aesKey = AES(Key.fromSecureRandom(32));
    var keyString = aesKey.key.base64;
    return keyString;
  }

  static String encryptValue(String value, String encryptionKey) {
    var aesEncrypter = Encrypter(AES(Key.fromBase64(encryptionKey)));
    var initializationVector = IV.fromLength(16);
    var encryptedValue = aesEncrypter.encrypt(value, iv: initializationVector);
    return encryptedValue.base64;
  }

  static String decryptValue(String encryptedValue, String decryptionKey) {
    try {
      var aesKey = AES(Key.fromBase64(decryptionKey));
      var decrypter = Encrypter(aesKey);
      var iv2 = IV.fromLength(16);
      return decrypter.decrypt64(encryptedValue, iv: iv2);
    } on Exception catch (e, trace) {
      _logger.severe('Exception while decrypting value: ${e.toString()} $trace');
      throw AtKeyException(e.toString());
    } on Error catch (e, trace) {
      // Catching error since underlying decryption library may throw Error e.g corrupt pad block
      _logger.severe('Error while decrypting value: ${e.toString()} $trace');
      throw AtKeyException(e.toString());
    }
  }

  static String encryptKey(String aesKey, String publicKey) {
    var rsaPublicKey = RSAPublicKey.fromString(publicKey);
    return rsaPublicKey.encrypt(aesKey);
  }

  static String decryptKey(String aesKey, String privateKey) {
    var rsaPrivateKey = RSAPrivateKey.fromString(privateKey);
    return rsaPrivateKey.decrypt(aesKey);
  }
}
