import FacebookManager, { FacebookListener } from "./Manager/FacebookManager";

const {ccclass, property} = cc._decorator;

@ccclass
export default class Helloworld extends cc.Component {

    @property(cc.Label)
    label: cc.Label = null;

    @property(cc.Sprite)
    image:cc.Sprite = null;

    @property(cc.Button)
    btnLoginOrLogout:cc.Button = null;


    @property(cc.Label)
    txtLoginOrLogout: cc.Label = null;

    @property
    text: string = 'hello';

    onLoad(){
        console.log("onLoad");
        let isLogin = FacebookManager.getInstance().isLoggedIn();
        if(!isLogin){
            this.txtLoginOrLogout.string = "Login";
        }
        else{
            this.txtLoginOrLogout.string = "Logout";
        }
        FacebookManager.getInstance().setListener({
            onLogin:function(data:string){
                console.log("Callback onLogin:", data);
            },
            onLogout:function(){
                console.log("Callback onLogout");
            },
            onGraphAPI:function(hasError:boolean,tag:string,graphPath:string,data:any){
                console.log("Callback onGraphAPI hasError:",hasError);
                console.log("Callback onGraphAPI tag:",tag);
                console.log("Callback onGraphAPI graphPath:",graphPath);
                console.log("Callback onGraphAPI data:",JSON.stringify(data));
            },
            onRefreshToken:function(newToken:string){
                console.log("Callback onRefreshToken:",newToken);
            }
        });
    }

    start () {
        // init logic
        this.label.string = this.text;
    }

    onBtnGraphAPIClick(){
        console.log("onBtnGraphAPIClick");
        let isLogin = FacebookManager.getInstance().isLoggedIn();
        if(isLogin){
            let params = { fields: "id,name,email,picture.width(100).height(100)" };
            FacebookManager.getInstance().executeGraphAPI("GET","/me","tagMe",params);
        }
    }

    onBtnGraphAPI2Click(){
        console.log("onBtnGraphAPI2Click");
        let isLogin = FacebookManager.getInstance().isLoggedIn();
        if(isLogin){
            let params = { fields: "id,name,email,picture.width(100).height(100)" };
            FacebookManager.getInstance().executeGraphAPI("GET","/me","tagMe2",params);
        }
    }

    onBtnTestClick(){
        console.log("onBtnTestClick");
    }

    onBtnLoginOrLogoutClick() {
        console.log("onBtnLoginOrLogoutClick");
        let isLogin = FacebookManager.getInstance().isLoggedIn();
        if(!isLogin){
            FacebookManager.getInstance().login();
        }
        else{
            FacebookManager.getInstance().logout();
        }
    }
    
}
