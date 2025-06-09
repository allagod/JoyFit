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


/**
 * 判断用户今天是否已提交体脂记录（防止重复记录）
 */
public async isTodayRecorded(uid: string): Promise<boolean> {
  const today = new Date();
  const todayInt = DateConverToNum.convertDateToInteger(today);

  const condition = new cloudDatabase.DatabaseQuery(BodyFatData)
    .equalTo('UserID', uid)
    .and()
    .equalTo('BodyFatRecordTime', todayInt);

  const result = await this.agcDataBase.query(condition);
  return result.length > 0;
}

/**
 * 获取最近 N 条体脂记录（按时间倒序）
 */
public async getRecentBodyFatRecords(uid: string, limit: number = 5) {
  const condition = new cloudDatabase.DatabaseQuery(BodyFatData)
    .equalTo('UserID', uid)
    .orderByDesc('BodyFatRecordTime')
    .limit(limit);

  return await this.agcDataBase.query(condition);
}

/**
 * 获取某时间段内的体脂数据
 */
public async getBodyFatByDateRange(uid: string, start: Date, end: Date) {
  const startInt = DateConverToNum.convertDateToInteger(start);
  const endInt = DateConverToNum.convertDateToInteger(end);

  const condition = new cloudDatabase.DatabaseQuery(BodyFatData)
    .equalTo('UserID', uid)
    .and()
    .greaterThanOrEqualTo('BodyFatRecordTime', startInt)
    .and()
    .lessThanOrEqualTo('BodyFatRecordTime', endInt);

  return await this.agcDataBase.query(condition);
}

/**
 * 获取体脂率的最大、最小、平均值
 */
public async getBodyFatStats(uid: string): Promise<{ max: number; min: number; avg: number } | null> {
  const records = await this.getBodyFatRateHistory(uid);
  if (!records || records.length === 0) return null;

  const rates = records.map((r: any) => r.BodyFatRate);
  const max = Math.max(...rates);
  const min = Math.min(...rates);
  const avg = rates.reduce((a, b) => a + b, 0) / rates.length;

  return { max, min, avg: parseFloat(avg.toFixed(2)) };
}

/**
 * 获取体脂率变化趋势（最近一次 vs 最早一次）
 */
public async getBodyFatTrend(uid: string): Promise<number | null> {
  const records = await this.getBodyFatRateHistory(uid);
  if (!records || records.length < 2) return null;

  const sorted = records.sort((a: any, b: any) => b.BodyFatRecordTime - a.BodyFatRecordTime);
  const latest = sorted[0].BodyFatRate;
  const oldest = sorted[sorted.length - 1].BodyFatRate;

  return parseFloat((latest - oldest).toFixed(2));
}

/**
 * 分页获取体脂记录
 */
public async getBodyFatPaginated(uid: string, page: number = 1, pageSize: number = 10) {
  const offset = (page - 1) * pageSize;
  const condition = new cloudDatabase.DatabaseQuery(BodyFatData)
    .equalTo('UserID', uid)
    .orderByDesc('BodyFatRecordTime')
    .limit(pageSize)
    .offset(offset);

  return await this.agcDataBase.query(condition);
}

/**
 * 获取每天的体脂记录数量（用于图表可视化）
 */
public async groupBodyFatByDate(uid: string): Promise<Record<string, number>> {
  const records = await this.getBodyFatRateHistory(uid);
  const grouped: Record<string, number> = {};

  records.forEach((record: any) => {
    const dateKey = record.BodyFatRecordTime.toString(); // 假设整数格式如 20250609
    grouped[dateKey] = (grouped[dateKey] || 0) + 1;
  });

  return grouped;
}
