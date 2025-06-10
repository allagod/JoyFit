import { ExerciseStates } from '../bean/ExerciseStates';
import { userExerciseStates } from '../model/userExerciseStates';
import { cloudDatabase } from '@kit.CloudFoundationKit';
import { cloudFunction } from '@kit.CloudFoundationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import {DateConverToNum}from "utils"
import { hilog } from '@kit.PerformanceAnalysisKit';

export class UserExerciseStatsService {
  private static instance: UserExerciseStatsService | null = null;
  private agcDataBase: cloudDatabase.DatabaseZone = cloudDatabase.zone('joyfit');


  private constructor() {}

  static getInstance(): UserExerciseStatsService {
    if (!UserExerciseStatsService.instance) {
      UserExerciseStatsService.instance = new UserExerciseStatsService();
    }
    return UserExerciseStatsService.instance;
  }

  // 将用户运动状态对象转换为数据库记录对象
  private mapToRecord(stats: userExerciseStates, userId: string): ExerciseStates {
    const record = new ExerciseStates();
    record.UserID = userId;
    record.TimeStamp = DateConverToNum.convertDateToInteger(stats.timeStamp);
    record.TotalSteps = stats.totalSteps;
    record.TotalExerciseTime = stats.totalExerciseTime;
    record.TotalCaloriesBurned = stats.totalCalorisesBurned; // 若有拼写错误建议修正

    return record;
  }

  // 更新用户的当日运动情况
  async updateUserExerciseStates(stats: userExerciseStates, userId: string): Promise<boolean> {
    const record = this.mapToRecord(stats, userId);

    try {
      const data: cloudFunction.FunctionResult = await new Promise((resolve, reject) => {
        cloudFunction.call({
          name: 'my-cloud-function',
          version: '$latest',
          timeout: 10 * 1000,
          data: {
            operation: 'upsert',
            records: record
          }
        }, (err: BusinessError, result: cloudFunction.FunctionResult) => {
          if (err) {
            console.error(`Cloud function failed. Code: ${err.code}, Message: ${err.message}`);
            reject(err);
          } else {
            console.info(`Cloud function succeeded. Result: ${JSON.stringify(result.result)}`);
            resolve(result);
          }
        });
      });

      return !!data.result;
    } catch (error) {
      console.error('Exception occurred while updating user exercise states:', error);
      return false;
    }
  }

  //按照日期查看用户运动情况
  async getUserExerciseStates(uid:string,dateinteger:number):Promise<ExerciseStates>{
    try {
      let condition = new cloudDatabase.DatabaseQuery(ExerciseStates);
      condition.equalTo('UserID', uid).equalTo("TimeStamp",dateinteger);

      let exercisestates = await this.agcDataBase.query(condition);
      if(exercisestates.length==0){
        console.log('该用户不存在该日期下的记录');
      }
      return exercisestates[0];

    } catch (err) {
      console.error(`Failed to query exercisestates. Code: ${err.code}, Message: ${err.message}`);
      throw new Error(`Failed to query exercisestates for user with ID and Date: ${uid}_${dateinteger}`);
    }


  }



}
