import { cloudDatabase } from "@kit.CloudFoundationKit";
import { BmiCalculator, DateConverToNum } from "utils";
import { BodyHeight } from "../bean/BodyHeight";
import { WeightData } from "../bean/WeightData";
import { BodyWeightService } from "./BodyWeightService";

/*
 * BodyWeightService.ts - 管理用户体重记录
 */
export class BodyWeightService {
  private static instance: BodyWeightService | null = null;
  private agcDataBase = cloudDatabase.zone('joyfit');

  private constructor() {}

  public static getInstance(): BodyWeightService {
    if (!BodyWeightService.instance) {
      BodyWeightService.instance = new BodyWeightService();
    }
    return BodyWeightService.instance;
  }

  public async getLatestWeightData(uid: string): Promise<WeightData | null> {
    if (!uid) return null;
    try {
      const query = new cloudDatabase.DatabaseQuery(WeightData)
        .equalTo('UserID', uid)
        .orderByDesc('WeightRecordTime')
        .limit(1);
      const result = await this.agcDataBase.query(query);
      return result[0] || null;
    } catch (err) {
      console.error('[getLatestWeightData] Error:', err);
      return null;
    }
  }

  public async updateWeight(uid: string, weight: number): Promise<boolean> {
    if (!uid || weight <= 0) return false;
    try {
      const record = new WeightData();
      record.UserID = uid;
      record.Weight = weight;
      record.WeightRecordTime = DateConverToNum.convertDateToInteger(new Date());
      const result = await this.agcDataBase.upsert(record);
      return result > 0;
    } catch (err) {
      console.error('[updateWeight] Error:', err);
      return false;
    }
  }

  public async deleteWeightRecord(uid: string, recordTime: number): Promise<boolean> {
    try {
      const query = new cloudDatabase.DatabaseQuery(WeightData)
        .equalTo('UserID', uid)
        .equalTo('WeightRecordTime', recordTime);
      const result = await this.agcDataBase.delete(query);
      return result > 0;
    } catch (err) {
      console.error('[deleteWeightRecord] Error:', err);
      return false;
    }
  }
}

/*
 * BmiHistoryService.ts - 管理用户 BMI 历史记录
 */
export class BmiHistoryService {
  private static instance: BmiHistoryService | null = null;
  private agcDataBase = cloudDatabase.zone('joyfit');

  private constructor() {}

  public static getInstance(): BmiHistoryService {
    if (!BmiHistoryService.instance) {
      BmiHistoryService.instance = new BmiHistoryService();
    }
    return BmiHistoryService.instance;
  }

  public async getLatestBMI(uid: string): Promise<number | null> {
    try {
      const query = new cloudDatabase.DatabaseQuery(WeightData)
        .equalTo('UserID', uid)
        .orderByDesc('WeightRecordTime')
        .limit(1);
      const result = await this.agcDataBase.query(query);
      return result[0]?.BMI || null;
    } catch (err) {
      console.error('[getLatestBMI] Error:', err);
      return null;
    }
  }

  public async getBmiHistory(uid: string, limit: number = 10): Promise<WeightData[]> {
    try {
      const query = new cloudDatabase.DatabaseQuery(WeightData)
        .equalTo('UserID', uid)
        .orderByDesc('WeightRecordTime')
        .limit(limit);
      return await this.agcDataBase.query(query);
    } catch (err) {
      console.error('[getBmiHistory] Error:', err);
      return [];
    }
  }
}

/*
 * BloodPressureService.ts - 血压记录服务
 */
export class BloodPressureService {
  private static instance: BloodPressureService | null = null;
  private agcDataBase = cloudDatabase.zone('joyfit');

  private constructor() {}

  public static getInstance(): BloodPressureService {
    if (!BloodPressureService.instance) {
      BloodPressureService.instance = new BloodPressureService();
    }
    return BloodPressureService.instance;
  }

  public async recordBloodPressure(uid: string, systolic: number, diastolic: number): Promise<boolean> {
    try {
      const record = new BloodPressureData();
      record.UserID = uid;
      record.Systolic = systolic;
      record.Diastolic = diastolic;
      record.RecordTime = DateConverToNum.convertDateToInteger(new Date());
      const result = await this.agcDataBase.upsert(record);
      return result > 0;
    } catch (err) {
      console.error('[recordBloodPressure] Error:', err);
      return false;
    }
  }

  public async getLatestBloodPressure(uid: string): Promise<BloodPressureData | null> {
    try {
      const query = new cloudDatabase.DatabaseQuery(BloodPressureData)
        .equalTo('UserID', uid)
        .orderByDesc('RecordTime')
        .limit(1);
      const result = await this.agcDataBase.query(query);
      return result[0] || null;
    } catch (err) {
      console.error('[getLatestBloodPressure] Error:', err);
      return null;
    }
  }
}

/*
 * BodyMetricsSummaryService.ts - 汇总用户体征数据
 */
export class BodyMetricsSummaryService {
  private heightService = BodyHeightService.getInstance();
  private weightService = BodyWeightService.getInstance();
  private bmiService = BmiHistoryService.getInstance();
  private bpService = BloodPressureService.getInstance();

  public async getLatestBodySummary(uid: string): Promise<any> {
    const [height, weight, bmi, bp] = await Promise.all([
      this.heightService.getLatestHeight(uid),
      this.weightService.getLatestWeightData(uid),
      this.bmiService.getLatestBMI(uid),
      this.bpService.getLatestBloodPressure(uid)
    ]);

    return {
      height: height?.Height || null,
      weight: weight?.Weight || null,
      bmi: bmi || null,
      bloodPressure: bp ? `${bp.Systolic}/${bp.Diastolic}` : null
    };
  }
}
