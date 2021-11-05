import 'package:communicationapi/src/communication/communication_secret.dart';
import 'package:communicationapi/src/communication/plugin_information.dart';
import 'package:test/test.dart';

void main(){
  var ports = [1025, 1700, 8000, 12500, 44555, 65535];
  var executables = ["thisApplication.jar", "./thisAccplication",
    "./../path/to/thisApplication", "C:/path to/this/application", "thisApplication.apk"];
  var secrets = [CommunicationSecret([1,2,3]), CommunicationSecret([4,5,6])];

  group("ConstructorGetter", (){
    for (var secret in secrets) {print(secret);}
    for (int port in ports){
      for (String executable in executables){
        for (CommunicationSecret secret in secrets){
          //Constructor without secret
          PluginInformation info = PluginInformation(executable, port);
          test("checking Executable", (){
            expect(info.getExecutable(), executable);
          });
          test("checking Port", (){
            expect(info.getPort(), port);
          });
          test("checking Secret", (){
            bool isNull = false;
              if(info.getSecret() == null){
                isNull = true;
              }
              expect(isNull, false);
          });
          //Constructor with secret
          PluginInformation info2 = PluginInformation(executable, port, secret);
          test("checking Executable", (){
            expect(info.getExecutable(), executable);
          });
          test("checking Port", (){
            expect(info.getPort(), port);
          });
          test("checking Secret", (){
            expect(info2.getSecret().secret, secret.secret);
          });
        }
      }
    }
  });
  group("Hash Code", (){
    for (int port in ports){
      for (String executable in executables){
        for (CommunicationSecret secret in secrets){
          PluginInformation info = PluginInformation(executable, port, secret);
          PluginInformation info2 = PluginInformation(executable, port, secret);
          test("checking Hashcode", (){
            expect(info.hashCode, info2.hashCode);
          });
        }
      }
    }
  });
}
