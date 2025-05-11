import { cloudDatabase } from '@kit.CloudFoundationKit';
import { BodyHeight } from '../bean/BodyHeight';
import { WeightData } from '../bean/WeightData';
import {BodyFatData} from '../bean/BodyFatData';
import { BmiCalculator, DateConverToNum} from "utils";
import { BodyHeightService } from './BodyHeightService';

export class BodyWeightService {
  private static instance: BodyWeightService | null = null;
  private agcDataBase: cloudDatabase.DatabaseZone = cloudDatabase.zone('joyfit');
  private bodyHeightService : BodyHeightService = BodyHeightService.getInstance();

  private constructor() {}

  static getInstance(): BodyWeightService {
    if (!BodyWeightService.instance) {
      BodyWeightService.instance = new BodyWeightService();
    }
    return BodyWeightService.instance;
  }

  //获取用户最新的WeigtData
  async getLatestWeightData(userID: string) {
      try {
         // 创建查询条件，查找指定 UserID 的 WeightData
        let condition = new cloudDatabase.DatabaseQuery(WeightData);
         condition.equalTo('UserID', userID);  // 根据 UserID 查找

         // 按 WeightRecordTime 降序排序，确保最新的记录排在前面
         condition.orderByDesc('WeightRecordTime');


         // 执行查询
         let weightDataArray = await this.agcDataBase.query(condition);

         // 检查查询结果
         if (weightDataArray.length === 0) {
           console.info(`No weight data found for user with ID: ${userID}`);
           return null;  // 如果没有找到，返回 null
         } else {
          // 返回最新的 WeightData（数组中的第一条记录）
           console.info(`Found latest weight data: ${JSON.stringify(weightDataArray[0])}`);
           return weightDataArray[0];  // 返回最新的记录
         }
       } catch (err) {
         console.error(`Failed to query weight data. Code: ${err.code}, Message: ${err.message}`);
         throw new Error(`Failed to get latest weight data for user with ID: ${userID}`);
       }
  }


  //用户增加历史体重，会引发BMI更新，作为外部调用接口
  async addWeight(uid:string,weight:number){
    if (!weight || !uid) {
      console.error('Invalid parameters: weight or uid is missing');
      return false;
    }
    try {
      let userweight=new WeightData();
      userweight.UserID=uid;
      userweight.Weight=weight;
      let currentDate = new Date();
      userweight.WeightRecordTime=DateConverToNum.convertDateToInteger(currentDate);
      // 获取该用户的身高数据
      let HeightData = await this.bodyHeightService.getUserHeight(uid);
      if(!HeightData){
        console.warn('Height data not found, BMI calculation skipped');
      }
      else {
        if (HeightData != null) {
          if ( HeightData.Height!=0&&HeightData.Height!=null) {
            // 计算BMI
            let newBMI = BmiCalculator.calculateBMI(HeightData.Height, userweight.Weight);
            userweight.BMI = newBMI;
          } else {
            console.warn('Height data is invalid or not found, BMI calculation skipped');
          }
        } else {
          console.warn('Height data not found, BMI calculation skipped');
        }
      }
      // 调用 upsert 方法
      let num = await this.agcDataBase.upsert([userweight]);


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

  //用户获取历史体重数据
  async getWeightHistory(uid:string){
    if(!uid){
      console.error('Invalid parameters: BodyFat or uid is missing');
      return false;
    }
    try{
       let condition = new cloudDatabase.DatabaseQuery(WeightData);
       condition.equalTo('UserID', uid);

       let WeightHistoryArray = await this.agcDataBase.query(condition);
       console.info(`Succeeded in querying , result: ${JSON.stringify(WeightHistoryArray)}`);
       return WeightHistoryArray;
    } catch (err) {
      console.error(`Failed to query , Code: ${err.code}, message: ${err.message}`);
      return false;
    }
  }
}
