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
