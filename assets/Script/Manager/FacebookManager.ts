// Learn TypeScript:
//  - https://docs.cocos.com/creator/manual/en/scripting/typescript.html
// Learn Attribute:
//  - https://docs.cocos.com/creator/manual/en/scripting/reference/attributes.html
// Learn life-cycle callbacks:
//  - https://docs.cocos.com/creator/manual/en/scripting/life-cycle-callbacks.html

import { Utils } from "../Utils/Utils";

const {ccclass, property} = cc._decorator;

@ccclass
export default class FacebookManager extends cc.Component {
    private static readonly FuncName: string = "FacebookFromJs";
    private static _instance: FacebookManager = null;
    public static getInstance() {
        if (this._instance == null) this._instance = new FacebookManager();
        return this._instance;
    }

    private listener:FacebookListener = null;
    public setListener(newListener: FacebookListener){
        this.listener = newListener;
    }

    public isLoggedIn():boolean{
        let value:string = Utils.CallNative(FacebookManager.FuncName,"CheckLogin","");
        console.log("isLoggedIn:", value);
        if(value == "true"){
            return true;
        }
        return false;
    }

    public login(){
        Utils.CallNative(FacebookManager.FuncName,"Login","");
    }

    public logout(){
        Utils.CallNative(FacebookManager.FuncName,"Logout","");
    }

    public executeGraphAPI(method:string,pathGraph:string,tag:string,params:any){
        let data = {
            'method':method,
            'tag':tag,
            'pathGraph':pathGraph,
            'params':params
        };
        Utils.CallNative(FacebookManager.FuncName,"GraphAPI",JSON.stringify(data));
    }

    public nativeCallBack(key: string, value: string) {
        console.log("AdsNative Callback with key:", key);
        console.log("AdsNative Callback with value:", value);
        /*if(this.onHandleFromNative != null){
            this.onHandleFromNative(key,value);
        }*/
        if (key == "Login") {
            if(this.listener != null){
                this.listener.onLogin(value);
            }
        }
        if (key == "Logout") {
            if(this.listener != null){
                this.listener.onLogout();
            }
        }
        if (key == "Refresh") {
            if(this.listener != null){
                this.listener.onRefreshToken(value);
            }
        }

        if (key == "GraphAPI") {
            if(this.listener != null){
                let jsonData = JSON.parse(value);
                let hasError:boolean = jsonData['hasError'];
                let tag:string = jsonData['tag'];
                let graphPath:string = jsonData['pathGraph'];
                let data:any = jsonData['data'];
                this.listener.onGraphAPI(hasError,tag,graphPath,data);
            }
        }
    }
}

export class FacebookListener {
    public onLogin: (data:string) => void = null;
    public onGraphAPI: (hasError:boolean,tag:string,graphPath:string,data:any) => void = null;
    public onRefreshToken:(newToken:string) => void = null;
    public onLogout: ()=> void = null;
}

window["facebookManager"] = FacebookManager.getInstance();