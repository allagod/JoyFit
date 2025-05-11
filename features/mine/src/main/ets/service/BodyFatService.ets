import { cloudDatabase } from "@kit.CloudFoundationKit";
import { DateConverToNum } from "utils";
import { BodyFatData } from "../bean/BodyFatData";


export class BodyFatService{

  private static instance: BodyFatService | null = null;
  private agcDataBase: cloudDatabase.DatabaseZone = cloudDatabase.zone('joyfit');

  private constructor() {}

  static getInstance(): BodyFatService {
    if (!BodyFatService.instance) {
      BodyFatService.instance = new BodyFatService();
    }
    return BodyFatService.instance;
  }


  //用户更新体脂数据
  async addBodyFatRate(uid:string,BodyFat:number){
    if(!uid||!BodyFat){
      console.error('Invalid parameters: BodyFat or uid is missing');
      return false;
    }
    try {
      let userBodyFat=new BodyFatData();
      userBodyFat.UserID=uid;
      userBodyFat.BodyFatRate=BodyFat;
      let currentDate = new Date();
      userBodyFat.BodyFatRecordTime=DateConverToNum.convertDateToInteger(currentDate);
      // 调用 upsert 方法
      let num = await this.agcDataBase.upsert([userBodyFat]);

      // 根据返回结果判断成功或失败
      if (num > 0) {
        console.info(`Successfully updated/inserted ${num} records.`);
        return true;
      } else {
        console.warn('No records were updated or inserted.');
        return false;
      }
    } catch (err) {
      // 错误处理
      console.error(`Failed to upsert, error: `, err);
      return false;
    }
  }


  //用户获取历史体脂数据
  async getBodyFatRateHistory(uid:string){
    if(!uid){
      console.error('Invalid parameters: BodyFat or uid is missing');
      return false;
    }
    try{
      let condition = new cloudDatabase.DatabaseQuery(BodyFatData);
      condition.equalTo('UserID', uid);

      let BodyFatDataHistoryArray = await this.agcDataBase.query(condition);
      console.info(`Succeeded in querying , result: ${JSON.stringify(BodyFatDataHistoryArray)}`);
      return BodyFatDataHistoryArray;
    } catch (err) {
      console.error(`Failed to query , Code: ${err.code}, message: ${err.message}`);
      return false;
    }
  }
}
