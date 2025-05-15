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
