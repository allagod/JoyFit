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
   * 修改用户身高，并自动更新 BMI（若有最新体重）
   */
  public async updateHeight(uid: string, newHeight: number): Promise<boolean> {
    if (!uid || !newHeight) {
      console.error('[updateHeight] Missing parameters');
      return false;
    }

    try {
      const heightEntry = new BodyHeight();
      heightEntry.UserID = uid;
      heightEntry.Height = newHeight;
      heightEntry.LastUpdateTime = new Date();

      const result = await this.agcDataBase.upsert(heightEntry);

      if (result <= 0) {
        console.warn('[updateHeight] No height records inserted');
        return false;
      }

      // 更新 BMI（如果有最新体重）
      const latestWeight = await this.bodyWeightService.getLatestWeightData(uid);
      if (latestWeight?.Weight) {
        const newBMI = BmiCalculator.calculateBMI(newHeight, latestWeight.Weight);
        await this.insertWeightWithBMI(uid, latestWeight.Weight, newBMI);
      }

      return true;
    } catch (err) {
      console.error('[updateHeight] Failed to update height:', err);
      return false;
    }
  }

  /**
   * 私有方法：根据体重和 BMI 插入体重记录
   */
  private async insertWeightWithBMI(uid: string, weight: number, bmi: number): Promise<boolean> {
    try {
      const weightRecord = new WeightData();
      weightRecord.UserID = uid;
      weightRecord.Weight = weight;
      weightRecord.BMI = bmi;
      weightRecord.WeightRecordTime = DateConverToNum.convertDateToInteger(new Date());

      const result = await this.agcDataBase.upsert(weightRecord);
      return result > 0;
    } catch (err) {
      console.error('[insertWeightWithBMI] Failed to insert BMI-linked weight record:', err);
      return false;
    }
  }
}
