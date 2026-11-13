// Importação condicional: no navegador entra a versão WebAuthn; em
// Android, iOS e Windows entra a versão com local_auth. Os dois arquivos
// expõem a mesma função criarBiometriaDaPlataforma().
export 'biometria_nativa.dart' if (dart.library.js_interop) 'biometria_web.dart';
