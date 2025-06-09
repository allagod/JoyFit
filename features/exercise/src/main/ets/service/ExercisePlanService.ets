import { cloudDatabase } from '@kit.CloudFoundationKit';
import {Action} from '../bean/Action'
import {RunningPlan} from'../bean/RunningPlan'
import {WorkoutPlan} from'../bean/WorkoutPlan'
import {PlanAction} from '../bean/PlanAction'
import {action} from '../model/action'
import { exercisePlan } from '../model/exercisePlan';
import { runningPlanBuilder } from '../model/runningPlanBuilder';
import { workoutPlanBuilder } from '../model/workoutPlanBuilder';
import { PlanTask } from '../bean/PlanTask';
import { UUIDGenerator } from 'utils';
import { RunningRecord } from '../bean/RunningRecord';
import { WorkoutRecord } from '../bean/WorkoutRecord';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { JSON } from '@kit.ArkTS';

export abstract class ExercisePlanService {

  //可以从用户首选项中读取UserID信息,这样就不需要每次调用服务都传参了
  protected agcDataBase: cloudDatabase.DatabaseZone = cloudDatabase.zone('joyfit');

  //上传/更新
  public abstract createPlanBuilder():runningPlanBuilder|workoutPlanBuilder;
  public abstract uploadPlan(plan:exercisePlan,userID:string);
  public abstract updatePlan(plan:exercisePlan,userID:string);
  //获取计划
  public abstract getCompletedPlan(userID:string);
  public abstract getNotStartedPlan(userID:string);
  public abstract getInProgressPlan(userID:string);
  public abstract getAbandonedPlan(userID:string);
  //删除/放弃计划
  public abstract deletePlan(planID:string);
  public abstract abandonInProgressPlan(plan:RunningPlan|WorkoutPlan);

}



// 获取所有计划（包含进行中、已完成、未开始、已放弃）
public async getAllPlans(userID: string): Promise<exercisePlan[]> {
  const condition = new cloudDatabase.DatabaseQuery(RunningPlan); // 或 WorkoutPlan，根据需要可拆分
  condition.equalTo('UserID', userID);
  const runningPlans = await this.agcDataBase.query(condition);

  const workoutQuery = new cloudDatabase.DatabaseQuery(WorkoutPlan);
  workoutQuery.equalTo('UserID', userID);
  const workoutPlans = await this.agcDataBase.query(workoutQuery);

  return [...runningPlans, ...workoutPlans];
}

// 根据时间范围查询计划（如：某周、某月）
public async getPlansByDateRange(userID: string, startDate: Date, endDate: Date): Promise<exercisePlan[]> {
  const condition = new cloudDatabase.DatabaseQuery(PlanTask);
  condition
    .equalTo('UserID', userID)
    .and()
    .greaterThanOrEqualTo('StartDate', startDate)
    .and()
    .lessThanOrEqualTo('EndDate', endDate);

  const result = await this.agcDataBase.query(condition);
  return result;
}

// 复制已有计划（返回新的plan对象但不上传）
public clonePlan(originalPlan: exercisePlan): exercisePlan {
  const newPlan = { ...originalPlan };
  newPlan.PlanID = UUIDGenerator.generateUUID();
  newPlan.Title = `${originalPlan.Title}（复制）`;
  newPlan.Status = 'notStarted';
  newPlan.CreateTime = new Date();
  return newPlan;
}

// 关键词搜索计划（按名称或备注）
public async searchPlansByKeyword(userID: string, keyword: string): Promise<exercisePlan[]> {
  const planQuery = new cloudDatabase.DatabaseQuery(RunningPlan); // 同样适用于 WorkoutPlan
  planQuery
    .equalTo('UserID', userID)
    .and()
    .contains('Title', keyword); // 若不支持 contains，可考虑转为前端过滤

  const runningResults = await this.agcDataBase.query(planQuery);

  const workoutQuery = new cloudDatabase.DatabaseQuery(WorkoutPlan);
  workoutQuery.equalTo('UserID', userID).and().contains('Title', keyword);
  const workoutResults = await this.agcDataBase.query(workoutQuery);

  return [...runningResults, ...workoutResults];
}

// 查询某个计划中所有的动作（适用于多任务型计划）
public async getActionsInPlan(planID: string): Promise<PlanAction[]> {
  const condition = new cloudDatabase.DatabaseQuery(PlanAction);
  condition.equalTo('PlanID', planID);
  return await this.agcDataBase.query(condition);
}

// 统计计划完成率（根据 PlanTask）
public async getPlanCompletionRate(planID: string): Promise<number> {
  const query = new cloudDatabase.DatabaseQuery(PlanTask);
  query.equalTo('PlanID', planID);
  const tasks = await this.agcDataBase.query(query);
  if (tasks.length === 0) return 0;

  const completed = tasks.filter(task => task.Status === 'completed').length;
  return (completed / tasks.length) * 100;
}

// 添加自定义标签
public async addTagToPlan(planID: string, tag: string): Promise<boolean> {
  const plan = await this.agcDataBase.get(cloudDatabase.ObjectId(planID), RunningPlan); // 或 WorkoutPlan
  if (!plan) return false;

  if (!plan.Tags) plan.Tags = [];
  if (!plan.Tags.includes(tag)) {
    plan.Tags.push(tag);
    await this.agcDataBase.upsert(plan);
  }

  return true;
}

// 获取所有标签计划统计
public async getPlansGroupedByTag(userID: string): Promise<{ [tag: string]: number }> {
  const query = new cloudDatabase.DatabaseQuery(RunningPlan); // 可双查 Running + Workout
  query.equalTo('UserID', userID);
  const plans = await this.agcDataBase.query(query);

  const tagStats: { [key: string]: number } = {};
  plans.forEach(plan => {
    if (Array.isArray(plan.Tags)) {
      plan.Tags.forEach(tag => {
        tagStats[tag] = (tagStats[tag] || 0) + 1;
      });
    }
  });

  return tagStats;
}


// 获取计划的任务总数、已完成和进行中的数量
public async getPlanProgress(planID: string): Promise<{ total: number; completed: number; inProgress: number }> {
  const query = new cloudDatabase.DatabaseQuery(PlanTask);
  query.equalTo('PlanID', planID);

  const tasks = await this.agcDataBase.query(query);
  const total = tasks.length;
  const completed = tasks.filter(task => task.Status === 'completed').length;
  const inProgress = tasks.filter(task => task.Status === 'inProgress').length;

  return { total, completed, inProgress };
}

// 根据计划ID和任务状态获取对应任务列表
public async getTasksByStatus(planID: string, status: string): Promise<PlanTask[]> {
  const query = new cloudDatabase.DatabaseQuery(PlanTask);
  query.equalTo('PlanID', planID).and().equalTo('Status', status);
  return await this.agcDataBase.query(query);
}

// 检查用户是否存在指定标题的跑步或力量训练计划
public async isPlanTitleExists(userID: string, title: string): Promise<boolean> {
  const query1 = new cloudDatabase.DatabaseQuery(RunningPlan);
  query1.equalTo('UserID', userID).and().equalTo('Title', title);
  const rPlans = await this.agcDataBase.query(query1);

  const query2 = new cloudDatabase.DatabaseQuery(WorkoutPlan);
  query2.equalTo('UserID', userID).and().equalTo('Title', title);
  const wPlans = await this.agcDataBase.query(query2);

  return rPlans.length > 0 || wPlans.length > 0;
}

// 为指定计划设置提醒时间
public async setReminderForPlan(planID: string, reminderTime: Date): Promise<boolean> {
  const plan = await this.agcDataBase.get(cloudDatabase.ObjectId(planID), RunningPlan); // 这里假设为跑步计划
  if (!plan) return false;

  plan.ReminderTime = reminderTime;
  await this.agcDataBase.upsert(plan);
  return true;
}

// 获取用户未来几天内即将开始的跑步和力量训练计划
public async getUpcomingPlans(userID: string, daysAhead: number = 3): Promise<exercisePlan[]> {
  const now = new Date();
  const future = new Date();
  future.setDate(now.getDate() + daysAhead);

  const query = new cloudDatabase.DatabaseQuery(RunningPlan);
  query.equalTo('UserID', userID)
    .and()
    .greaterThanOrEqualTo('StartDate', now)
    .and()
    .lessThanOrEqualTo('StartDate', future);
  const running = await this.agcDataBase.query(query);

  const workoutQuery = new cloudDatabase.DatabaseQuery(WorkoutPlan);
  workoutQuery.equalTo('UserID', userID)
    .and()
    .greaterThanOrEqualTo('StartDate', now)
    .and()
    .lessThanOrEqualTo('StartDate', future);
  const workout = await this.agcDataBase.query(workoutQuery);

  return [...running, ...workout];
}

// 根据计划ID和类型获取对应的训练记录
public async getRecordsByPlan(planID: string, type: 'running' | 'workout'): Promise<RunningRecord[] | WorkoutRecord[]> {
  const recordClass = type === 'running' ? RunningRecord : WorkoutRecord;
  const query = new cloudDatabase.DatabaseQuery(recordClass);
  query.equalTo('PlanID', planID);
  return await this.agcDataBase.query(query);
}

// 统计用户当前进行中的跑步和力量训练计划数量
public async countInProgressPlans(userID: string): Promise<number> {
  const runningQuery = new cloudDatabase.DatabaseQuery(RunningPlan);
  runningQuery.equalTo('UserID', userID).and().equalTo('Status', 'inProgress');
  const runningPlans = await this.agcDataBase.query(runningQuery);

  const workoutQuery = new cloudDatabase.DatabaseQuery(WorkoutPlan);
  workoutQuery.equalTo('UserID', userID).and().equalTo('Status', 'inProgress');
  const workoutPlans = await this.agcDataBase.query(workoutQuery);

  return runningPlans.length + workoutPlans.length;
}
