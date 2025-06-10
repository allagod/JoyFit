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
 * 检查用户今天是否已记录体脂数据
 * @param uid - 用户ID
 * @returns 若已有记录返回 true，否则 false
 */
public async isTodayRecorded(uid: string): Promise<boolean> {
  try {
    const today = new Date();
    const todayInt = DateConverToNum.convertDateToInteger(today);

    const query = new cloudDatabase.DatabaseQuery(BodyFatData)
      .equalTo('UserID', uid)
      .and()
      .equalTo('BodyFatRecordTime', todayInt);

    const result = await this.agcDataBase.query(query);
    return result.length > 0;
  } catch (err) {
    console.error('Failed to check today\'s body fat record:', err);
    return false;
  }
}

/**
 * 获取用户最近 N 条体脂记录（按时间倒序排列）
 * @param uid - 用户ID
 * @param limit - 获取数量限制，默认 5
 */
public async getRecentBodyFatRecords(uid: string, limit: number = 5) {
  try {
    const query = new cloudDatabase.DatabaseQuery(BodyFatData)
      .equalTo('UserID', uid)
      .orderByDesc('BodyFatRecordTime')
      .limit(limit);

    return await this.agcDataBase.query(query);
  } catch (err) {
    console.error('Failed to fetch recent body fat records:', err);
    return [];
  }
}

/**
 * 获取指定时间范围内的体脂记录
 * @param uid - 用户ID
 * @param start - 开始日期
 * @param end - 结束日期
 */
public async getBodyFatByDateRange(uid: string, start: Date, end: Date) {
  try {
    const startInt = DateConverToNum.convertDateToInteger(start);
    const endInt = DateConverToNum.convertDateToInteger(end);

    const query = new cloudDatabase.DatabaseQuery(BodyFatData)
      .equalTo('UserID', uid)
      .and()
      .greaterThanOrEqualTo('BodyFatRecordTime', startInt)
      .and()
      .lessThanOrEqualTo('BodyFatRecordTime', endInt);

    return await this.agcDataBase.query(query);
  } catch (err) {
    console.error('Failed to fetch body fat data by date range:', err);
    return [];
  }
}

/**
 * 统计用户体脂率的最大值、最小值和平均值
 * @param uid - 用户ID
 * @returns 包含 max/min/avg 的对象，或 null（无记录）
 */
public async getBodyFatStats(uid: string): Promise<{ max: number; min: number; avg: number } | null> {
  try {
    const records = await this.getBodyFatRateHistory(uid);
    if (!records?.length) return null;

    const rates = records.map((r: any) => r.BodyFatRate);
    const max = Math.max(...rates);
    const min = Math.min(...rates);
    const avg = parseFloat((rates.reduce((a, b) => a + b, 0) / rates.length).toFixed(2));

    return { max, min, avg };
  } catch (err) {
    console.error('Failed to calculate body fat stats:', err);
    return null;
  }
}

/**
 * 获取体脂变化趋势（最近一次体脂率 - 最早一次体脂率）
 * @param uid - 用户ID
 * @returns 差值（可正可负），或 null（记录不足）
 */
public async getBodyFatTrend(uid: string): Promise<number | null> {
  try {
    const records = await this.getBodyFatRateHistory(uid);
    if (!records || records.length < 2) return null;

    const sorted = records.sort((a: any, b: any) => b.BodyFatRecordTime - a.BodyFatRecordTime);
    const latest = sorted[0].BodyFatRate;
    const oldest = sorted[sorted.length - 1].BodyFatRate;

    return parseFloat((latest - oldest).toFixed(2));
  } catch (err) {
    console.error('Failed to compute body fat trend:', err);
    return null;
  }
}

/**
 * 分页获取体脂记录
 * @param uid - 用户ID
 * @param page - 页码（从 1 开始）
 * @param pageSize - 每页数量
 */
public async getBodyFatPaginated(uid: string, page: number = 1, pageSize: number = 10) {
  try {
    const offset = (page - 1) * pageSize;

    const query = new cloudDatabase.DatabaseQuery(BodyFatData)
      .equalTo('UserID', uid)
      .orderByDesc('BodyFatRecordTime')
      .limit(pageSize)
      .offset(offset);

    return await this.agcDataBase.query(query);
  } catch (err) {
    console.error('Failed to fetch paginated body fat data:', err);
    return [];
  }
}

/**
 * 统计用户每天的体脂记录数（用于图表可视化）
 * @param uid - 用户ID
 * @returns 以日期为键、数量为值的映射对象
 */
public async groupBodyFatByDate(uid: string): Promise<Record<string, number>> {
  try {
    const records = await this.getBodyFatRateHistory(uid);
    const grouped: Record<string, number> = {};

    records.forEach((record: any) => {
      const dateKey = record.BodyFatRecordTime.toString(); // 例如 20250609
      grouped[dateKey] = (grouped[dateKey] || 0) + 1;
    });

    return grouped;
  } catch (err) {
    console.error('Failed to group body fat records by date:', err);
    return {};
  }
}
