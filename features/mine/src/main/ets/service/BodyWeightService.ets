import { cloudDatabase } from '@kit.CloudFoundationKit';
import { WeightData } from '../bean/WeightData';
import { BodyHeightService } from './BodyHeightService';
import { BmiCalculator, DateConverToNum } from 'utils';

export class BodyWeightService {
  private static instance: BodyWeightService | null = null;
  private agcDataBase = cloudDatabase.zone('joyfit');
  private bodyHeightService = BodyHeightService.getInstance();

  private constructor() {}

  public static getInstance(): BodyWeightService {
    if (!BodyWeightService.instance) {
      BodyWeightService.instance = new BodyWeightService();
    }
    return BodyWeightService.instance;
  }

  /**
   * 获取用户最新体重记录
   */
  public async getLatestWeightData(userID: string): Promise<WeightData | null> {
    if (!userID) {
      console.error('[getLatestWeightData] userID is required');
      return null;
    }

    try {
      const query = new cloudDatabase.DatabaseQuery(WeightData)
        .equalTo('UserID', userID)
        .orderByDesc('WeightRecordTime')
        .limit(1);

      const result = await this.agcDataBase.query(query);
      return result[0] || null;
    } catch (err) {
      console.error(`[getLatestWeightData] Query failed:`, err);
      return null;
    }
  }

  /**
   * 新增用户体重记录，如果有身高信息则同时计算并保存 BMI
   */
  public async recordWeight(userID: string, weight: number): Promise<boolean> {
    if (!userID || !weight) {
      console.error('[recordWeight] userID and weight are required');
      return false;
    }

    const record = new WeightData();
    record.UserID = userID;
    record.Weight = weight;
    record.WeightRecordTime = DateConverToNum.convertDateToInteger(new Date());

    try {
      const heightInfo = await this.bodyHeightService.getLatestHeight(userID);
      if (heightInfo?.Height) {
        record.BMI = BmiCalculator.calculateBMI(heightInfo.Height, weight);
      }

      const result = await this.agcDataBase.upsert(record);
      return result > 0;
    } catch (err) {
      console.error('[recordWeight] Failed to insert weight record:', err);
      return false;
    }
  }

  /**
   * 获取用户的全部历史体重记录
   */
  public async getWeightHistory(userID: string): Promise<WeightData[] | null> {
    if (!userID) {
      console.error('[getWeightHistory] userID is required');
      return null;
    }

    try {
      const query = new cloudDatabase.DatabaseQuery(WeightData)
        .equalTo('UserID', userID)
        .orderByDesc('WeightRecordTime');

      const history = await this.agcDataBase.query(query);
      return history;
    } catch (err) {
      console.error('[getWeightHistory] Failed to query history:', err);
      return null;
    }
  }
}
