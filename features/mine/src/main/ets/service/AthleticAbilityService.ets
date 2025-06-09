import {athleticAbility} from "../model/athleticAbility"
import { cloudDatabase } from '@kit.CloudFoundationKit';
import { AthleticAbility } from '../bean/AthleticAbility';
import {DateConverToNum} from "utils";

export class AthleticAbilityService{
  private static instance: AthleticAbilityService|null = null;
  private agcDataBase: cloudDatabase.DatabaseZone = cloudDatabase.zone('joyfit');

  private constructor() {}

  static getInstance(): AthleticAbilityService {
    if (!AthleticAbilityService.instance) {
      AthleticAbilityService.instance = new AthleticAbilityService();
    }
    return AthleticAbilityService.instance;
  }

  // 用户更新运动能力信息
  async updateInfo(newInfo: athleticAbility, userId: string): Promise<boolean> {
    if (!userId || !newInfo) {
      console.error('参数错误：缺少 userId 或运动能力信息');
      return false;
    }

    const ability = new AthleticAbility();
    ability.UserID = userId;
    ability.RunningDistance = newInfo.runningDistance;
    ability.PushUpNums = newInfo.pushUpNums;
    ability.SquatNums = newInfo.squatNums;
    ability.CrunchNums = newInfo.crunchNums;
    ability.LastUpdated = DateConverToNum.convertDateToInteger(new Date());

    try {
      const affectedRows = await this.agcDataBase.upsert(ability);

      if (affectedRows > 0) {
        console.info(`更新成功，共影响 ${affectedRows} 条记录`);
        return true;
      } else {
        console.warn('没有记录被更新或插入');
        return false;
      }
    } catch (error) {
      console.error('更新失败，错误信息：', error);
      return false;
    }
  }


  async getInfoByUserID(uid:string){
    if (!uid) {
      console.error('Invalid parameters: height or uid is missing');
      return false;
    }
    try {
      // 创建查询条件，查找指定 UserID 的 WeightData
      let condition = new cloudDatabase.DatabaseQuery(AthleticAbility);
      condition.equalTo('UserID', uid);  // 根据 UserID 查找

      condition.orderByDesc('LastUpdated');

      // 执行查询
      let InfoArray = await this.agcDataBase.query(condition);

      // 检查查询结果
      if (InfoArray == null) {
        console.info(`No height data found for user with ID: ${uid}`);
        return null;  // 如果没有找到，返回 null
      } else {

        console.info(`Found latest height data: ${JSON.stringify(InfoArray[0])}`);
        return InfoArray[0];
      }
    } catch (err) {
      console.error(`Failed to query weight data. Code: ${err.code}, Message: ${err.message}`);
      throw new Error(`Failed to get latest weight data for user with ID: ${uid}`);
    }
  }
}


/**
 * 获取最近一次和最早一次记录之间的变化情况（增减趋势）
 */
public async getAbilityChangeTrend(userId: string) {
  const condition = new cloudDatabase.DatabaseQuery(AthleticAbility)
    .equalTo('UserID', userId)
    .orderByDesc('LastUpdated');

  const records = await this.agcDataBase.query(condition);
  if (records.length < 2) return null;

  const latest = records[0];
  const earliest = records[records.length - 1];

  return {
    PushUpChange: latest.PushUpNums - earliest.PushUpNums,
    SquatChange: latest.SquatNums - earliest.SquatNums,
    CrunchChange: latest.CrunchNums - earliest.CrunchNums,
    RunningChange: latest.RunningDistance - earliest.RunningDistance
  };
}

/**
 * 获取用户过去 N 天的运动能力变化记录（按时间倒序）
 */
public async getRecentAbilityHistory(userId: string, days: number = 7) {
  const today = new Date();
  const cutoff = new Date(today.getTime() - days * 24 * 60 * 60 * 1000);

  const condition = new cloudDatabase.DatabaseQuery(AthleticAbility)
    .equalTo('UserID', userId)
    .and()
    .greaterThanOrEqualTo('LastUpdated', DateConverToNum.convertDateToInteger(cutoff))
    .orderByDesc('LastUpdated');

  return await this.agcDataBase.query(condition);
}

/**
 * 判断今日是否已经提交了能力记录（防止重复提交）
 */
public async isTodayRecordExists(userId: string): Promise<boolean> {
  const todayInt = DateConverToNum.convertDateToInteger(new Date());

  const condition = new cloudDatabase.DatabaseQuery(AthleticAbility)
    .equalTo('UserID', userId)
    .and()
    .equalTo('LastUpdated', todayInt);

  const result = await this.agcDataBase.query(condition);
  return result.length > 0;
}

/**
 * 获取某一项（如俯卧撑）能力的最大记录值
 */
public async getMaxAbilityValue(userId: string, field: keyof AthleticAbility): Promise<number | null> {
  const condition = new cloudDatabase.DatabaseQuery(AthleticAbility)
    .equalTo('UserID', userId)
    .orderByDesc(field)
    .limit(1);

  const result = await this.agcDataBase.query(condition);
  return result.length > 0 ? result[0][field] : null;
}

/**
 * 统计某用户提交的运动能力记录总数
 */
public async getTotalRecordCount(userId: string): Promise<number> {
  const condition = new cloudDatabase.DatabaseQuery(AthleticAbility)
    .equalTo('UserID', userId);

  const result = await this.agcDataBase.query(condition);
  return result.length;
}

/**
 * 获取运动能力历史记录中每日记录数量（可用于图表分析）
 */
public async getDailyRecordDistribution(userId: string): Promise<Record<string, number>> {
  const condition = new cloudDatabase.DatabaseQuery(AthleticAbility)
    .equalTo('UserID', userId)
    .orderByDesc('LastUpdated');

  const result = await this.agcDataBase.query(condition);
  const distribution: Record<string, number> = {};

  result.forEach(record => {
    const dateStr = record.LastUpdated.toString(); // 假设为整数格式日期
    distribution[dateStr] = (distribution[dateStr] || 0) + 1;
  });

  return distribution;
}
