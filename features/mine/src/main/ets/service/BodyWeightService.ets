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


  // 外部接口：新增用户体重记录，若有身高则计算BMI
  async addWeight(userId: string, weight: number): Promise<boolean> {
    if (!userId || !weight) {
      console.error('参数错误：缺少 userId 或 weight');
      return false;
    }

    const record = new WeightData();
    record.UserID = userId;
    record.Weight = weight;
    record.WeightRecordTime = DateConverToNum.convertDateToInteger(new Date());

    try {
      // 获取用户身高信息
      const heightInfo = await this.bodyHeightService.getUserHeight(userId);

      if (heightInfo && heightInfo.Height) {
        const bmi = BmiCalculator.calculateBMI(heightInfo.Height, weight);
        record.BMI = bmi;
      } else {
        console.warn('未获取到有效身高信息，跳过 BMI 计算');
      }

      // 插入或更新体重记录
      const affectedRows = await this.agcDataBase.upsert([record]);

      if (affectedRows > 0) {
        console.info(`成功插入/更新体重记录，影响行数：${affectedRows}`);
        return true;
      } else {
        console.warn('没有记录被插入或更新');
        return false;
      }

    } catch (error) {
      console.error('插入体重记录失败，错误信息：', error);
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
