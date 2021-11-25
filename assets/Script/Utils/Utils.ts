// Learn TypeScript:
//  - https://docs.cocos.com/creator/manual/en/scripting/typescript.html
// Learn Attribute:
//  - https://docs.cocos.com/creator/manual/en/scripting/reference/attributes.html
// Learn life-cycle callbacks:
//  - https://docs.cocos.com/creator/manual/en/scripting/life-cycle-callbacks.html

const {ccclass, property} = cc._decorator;

export class Utils {
    public static CallNative(functionName: string, key: string, value: string = "No parameter"): string {
        if (!cc.sys.isNative || !cc.sys.isMobile) {
          cc.warn("Please use the Native function on your mobile device");
          return;
        }
    
        let result: string;
        switch (cc.sys.platform) {
          case cc.sys.ANDROID: {
            if (!functionName) {
              functionName = "InfoFromJs";
            }
            result = jsb.reflection.callStaticMethod("org/cocos2dx/javascript/AppActivity", functionName, "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;", key, value);
            break;
          }
          case cc.sys.IPHONE:
          case cc.sys.IPAD: {
            if (!functionName) {
              functionName = "InfoFromJs:value:";
            }
            else{
              functionName = `${functionName}:value:`
            }
            result = jsb.reflection.callStaticMethod("AppController", functionName, key, value);
            break;
          }
          default: {
            cc.warn("Only supports iPhone, Adnroid, iPad devices");
            break;
          }
        }
        cc.log(`Js_To_Native========>method:${key};value:${value};result:${result}`);
        console.log(`Js_To_Native========>method:${key};value:${value};result:${result}`);
        return result;
      }
}
