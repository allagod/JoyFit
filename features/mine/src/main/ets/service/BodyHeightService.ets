import { cloudDatabase } from "@kit.CloudFoundationKit";
import { BmiCalculator, DateConverToNum } from "utils";
import { BodyHeight } from "../bean/BodyHeight";
import { WeightData } from "../bean/WeightData";
import{BodyWeightService} from "./BodyWeightService"


export class BodyHeightService{

  private static instance: BodyHeightService | null = null;
  private bodyWeightService: BodyWeightService = BodyWeightService.getInstance();
  private agcDataBase: cloudDatabase.DatabaseZone = cloudDatabase.zone('joyfit');

  private constructor() {}

  static getInstance(): BodyHeightService {
    if (!BodyHeightService.instance) {
      BodyHeightService.instance = new BodyHeightService();
    }
    return BodyHeightService.instance;
  }

  //获取用户身高BodyHeight
  async getUserHeight(uid:string){
    if (!uid) {
      console.error('Invalid parameters: height or uid is missing');
      return false;
    }
    try {
      // 创建查询条件，查找指定 UserID 的 WeightData
      let condition = new cloudDatabase.DatabaseQuery(BodyHeight);
      condition.equalTo('UserID', uid);  // 根据 UserID 查找

      // 执行查询
      let HeightData = await this.agcDataBase.query(condition);

      // 检查查询结果
      if (HeightData == null) {
        console.info(`No height data found for user with ID: ${uid}`);
        return null;  // 如果没有找到，返回 null
      } else {

        console.info(`Found latest height data: ${JSON.stringify(HeightData[0].Height)}`);
        return HeightData[0];
      }
    } catch (err) {
      console.error(`Failed to query weight data. Code: ${err.code}, Message: ${err.message}`);
      throw new Error(`Failed to get latest weight data for user with ID: ${uid}`);
    }
  }

  //用户修改身高，会引发BMI更新
  async modifyheight(uid:string,height:number){
    if (!height || !uid) {
      console.error('Invalid parameters: height or uid is missing');
      return false;
    }

    try {
      let userheight=new BodyHeight();
      userheight.UserID=uid;
      userheight.Height=height;
      let currentDate = new Date();
      userheight.LastUpdateTime=currentDate;

      // 调用 upsert 方法
      let num = await this.agcDataBase.upsert([userheight]);

      // 获取最新体重数据
      let latestweightdata = await this.bodyWeightService.getLatestWeightData(uid);
      if (latestweightdata?.Weight != null) {
        let latestBMI = BmiCalculator.calculateBMI(height, latestweightdata.Weight);
        // 更新体重数据的 BMI
        await this.updateWeight(uid, latestweightdata.Weight, latestBMI);
      } else {
        console.warn('No weight data found to update BMI');
      }
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

  //更新WeightData，用于该层modifyheight()函数使用
  private async updateWeight(uid:string,weight:number,newBMI:number){
    if (!weight || !uid|| !newBMI) {
      console.error('Invalid parameters: weight or uid or newBMI is missing');
      return false;
    }
    try {
      let userweight=new WeightData();
      userweight.UserID=uid;
      userweight.Weight=weight;
      userweight.BMI=newBMI;
      let currentDate = new Date();
      userweight.WeightRecordTime=DateConverToNum.convertDateToInteger(currentDate);

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

}
