import { cloudDatabase } from "@kit.CloudFoundationKit";
import { BmiCalculator, DateConverToNum } from "utils";
import { BodyHeight } from "../bean/BodyHeight";
import { WeightData } from "../bean/WeightData";
import { BodyWeightService } from "./BodyWeightService";

export class BodyHeightService {
  private static instance: BodyHeightService | null = null;
  private agcDataBase = cloudDatabase.zone('joyfit');
  private bodyWeightService = BodyWeightService.getInstance();

  private constructor() {}

  public static getInstance(): BodyHeightService {
    if (!BodyHeightService.instance) {
      BodyHeightService.instance = new BodyHeightService();
    }
    return BodyHeightService.instance;
  }

  /**
   * 获取用户最新身高记录
   */
  public async getLatestHeight(uid: string): Promise<BodyHeight | null> {
    if (!uid) {
      console.error('[getLatestHeight] Missing UID');
      return null;
    }

    try {
      const query = new cloudDatabase.DatabaseQuery(BodyHeight)
        .equalTo('UserID', uid)
        .orderByDesc('LastUpdateTime')
        .limit(1);

      const result = await this.agcDataBase.query(query);
      return result[0] || null;
    } catch (err) {
      console.error(`[getLatestHeight] Query failed:`, err);
      return null;
    }
  }

  /**
 * 更新用户身高记录，并在有最新体重数据的情况下同步更新 BMI。
 * @param uid - 用户ID
 * @param newHeight - 新的身高值（厘米）
 * @returns 是否更新成功
 */
public async updateHeight(uid: string, newHeight: number): Promise<boolean> {
  if (!uid || typeof newHeight !== 'number' || newHeight <= 0) {
    console.error('[updateHeight] Invalid parameters: uid or newHeight');
    return false;
  }

  try {
    const heightRecord = new BodyHeight();
    heightRecord.UserID = uid;
    heightRecord.Height = newHeight;
    heightRecord.LastUpdateTime = new Date();

    const affectedRows = await this.agcDataBase.upsert(heightRecord);
    if (affectedRows <= 0) {
      console.warn('[updateHeight] No height record inserted or updated');
      return false;
    }

    // 如果存在最新体重记录，则同步更新 BMI
    const latestWeight = await this.bodyWeightService.getLatestWeightData(uid);
    if (latestWeight?.Weight) {
      const bmi = BmiCalculator.calculateBMI(newHeight, latestWeight.Weight);
      const bmiUpdated = await this.insertWeightWithBMI(uid, latestWeight.Weight, bmi);
      if (!bmiUpdated) {
        console.warn('[updateHeight] BMI not updated properly');
      }
    }

    return true;
  } catch (err) {
    console.error('[updateHeight] Exception during height update:', err);
    return false;
  }
}

/**
 * 私有方法：插入带有 BMI 的体重记录（用于同步更新）
 * @param uid - 用户ID
 * @param weight - 当前体重（kg）
 * @param bmi - 计算出的 BMI 值
 * @returns 是否插入成功
 */
private async insertWeightWithBMI(uid: string, weight: number, bmi: number): Promise<boolean> {
  try {
    const record = new WeightData();
    record.UserID = uid;
    record.Weight = weight;
    record.BMI = bmi;
    record.WeightRecordTime = DateConverToNum.convertDateToInteger(new Date());

    const result = await this.agcDataBase.upsert(record);
    return result > 0;
  } catch (err) {
    console.error('[insertWeightWithBMI] Failed to insert weight record with BMI:', err);
    return false;
  }
}
