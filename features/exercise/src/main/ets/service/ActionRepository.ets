import {action} from '../model/action';
import {Action} from '../bean/Action';
import {UserAction} from '../bean/UserAction';
import {PlanAction} from '../bean/PlanAction';
import { cloudFunction } from '@kit.CloudFoundationKit';
import { BusinessError } from '@kit.BasicServicesKit';

interface RetofResult {
  code: number;
  desc: string;
}

interface ResultofActionSearch {
  ret: RetofResult;
  result: Action[];
}

interface ResultofUserActionSearch {
  ret: RetofResult;
  result: UserAction[];
}

interface ResultofPlanActionSearch {
  ret: RetofResult;
  result: PlanAction[];
}

interface ResultofUserSingleActionSearch {
  ret: RetofResult;
  result: Action;
}

export class ActionRepository {
  private static instance: ActionRepository | null = null;

  private constructor() {}

  static getInstance(): ActionRepository {9
    if (!ActionRepository.instance) {
      ActionRepository.instance = new ActionRepository();
    }
    return ActionRepository.instance;
  }

  private ToBean(newAction: action){
    let action=new Action();
    action.ActionID=newAction.basicInfo?.ActionID;
    action.ActionName=newAction.basicInfo?.ActionName;
    action.Note=newAction.Note;
    action.IntroductionVideo=newAction.IntroductionVideo;
    action.IntroductionVoice=newAction.IntroductionVoice;
    action.Description=newAction.Description;
    action.TimeOfOne=newAction.TimeOfOne;
    action.MainTrainingPart=newAction.MainTrainingPart;
    action.IsUserDefined=true;
    action.Calories=newAction.Calories;

    return action;
  }

  private ToBeanUserAction(userID:string,actionID:string){
    let useraction=new UserAction();
    useraction.ActionID=actionID;
    useraction.UserID=userID;

    return useraction;
  }

  private async getAllActions(bodyPart: string):Promise<Action[]>{
    let operation: string = "queryActionof" + bodyPart;
    try {
      const data: cloudFunction.FunctionResult = await new Promise((resolve, reject) => {
        cloudFunction.call({
          name: 'action-bycyb-cloud-function',
          version: '$latest',
          timeout: 10 * 1000,
          data: {
            operation: operation,
          }
        }, (err: BusinessError, data: cloudFunction.FunctionResult) => {
          if (err) {
            console.error(`Failed to call the function, Code: ${err.code}, message: ${err.message}`);
            reject(false);  // Reject with false or any relevant error information
          } else {
            console.info(`Succeeded in calling the function, result: ${JSON.stringify(data.result)}`+data.result.toString());
            console.info(data.result.toString());
            resolve(data);  // Resolve with the data from the cloud function
          }
        });
      });
      // 处理查询结果并返回
      const cfReturn = data.result as ResultofActionSearch;
      console.info(cfReturn.result.toString());
      return cfReturn.result;

    } catch (error) {
      // 捕获错误并返回 false
      console.error('Error occurred:', error);
      return [];
    }
  }

  //获取所有的胸部动作
  async getAllChestActions():Promise<Action[] >{
      return this.getAllActions('Chest')
  }

  //获取所有的背部动作
  async getAllBackActions():Promise<Action[] | boolean>{
    return this.getAllActions('Back')
  }

  //获取所有的腿部动作
  async getAllLegActions():Promise<Action[] | boolean>{
    return this.getAllActions('Leg')
  }

  //获取所有的手臂动作
  async getAllArmsActions(): Promise<Action[] | boolean> {
    return this.getAllActions('Arms')
  }


  //获取所有的腹部动作
  async getAllAbdomenActions():Promise<Action[] | boolean>{
    return this.getAllActions('Abdomen')
  }

  //获取所有的肩部动作
  async getAllShouldersActions(): Promise<Action[] |boolean> {
    return this.getAllActions('Shoulders')
  }


  // 新增动作并与用户关联
  async addNewAction(newAction: action, uid: string): Promise<boolean> {
    const actionRecord = this.ToBean(newAction);

    // 若动作ID不存在，直接返回失败
    if (!actionRecord.ActionID) return false;

    const userActionRecord = this.ToBeanUserAction(uid, actionRecord.ActionID);

    try {
      // 上传或更新 Action 记录
      const upsertActionSuccess = await this.invokeCloudFunction('upsertAction', actionRecord);
      if (!upsertActionSuccess) return false;

      // 上传或更新 UserAction 记录
      const upsertUserActionSuccess = await this.invokeCloudFunction('upsertUserAction', userActionRecord);
      if (!upsertUserActionSuccess) return false;

      return true;
    } catch (error) {
      console.error("addNewAction error:", error);
      return false;
    }
  }

  // 封装 cloudFunction 调用逻辑
  private async invokeCloudFunction(operation: string, records: any): Promise<boolean> {
    return new Promise((resolve, reject) => {
     cloudFunction.call(
       {
          name: 'action-bycyb-cloud-function',
          version: '$latest',
          timeout: 10000,
          data: {
            operation,
            records
          }
        },
        (err: BusinessError, data: cloudFunction.FunctionResult) => {
          if (err) {
            console.error(`Cloud function [${operation}] failed:`, err);
            reject(false);
          } else {
            console.info(`Cloud function [${operation}] success:`, data.result);
            resolve(true);
          }
        }
      );
    });
  }



  //deleteMyAction
  // deleteMyAction(actionID: Integer): boolean
  async deleteMyAction(oldAction: action,uid:string):Promise<boolean>{

    let issuccess=true;
    let relationActionwithPlan=false;
    let actionID=oldAction.basicInfo?.ActionID;

    //测试用例
    //{
    //   "operation": "relationActionWithPlan",
    //   "records": "12345"
    // }

    //判断是否有计划相关联
    cloudFunction.call({
      name: 'action-bycyb-cloud-function',
      version: '$latest',
      timeout: 10 * 1000,
      data: {
        operation: 'relationActionWithPlan',
        records: actionID
      }
    }, (err: BusinessError, data: cloudFunction.FunctionResult) => {
      if (err) {
        console.error(`Failed to call the function, Code: ${err.code}, message: ${err.message}`);
        issuccess=false;
      }
      console.info(`Succeeded in calling the function, result: ${JSON.stringify(data.result)}`);
      const resultofRelation=data.result as ResultofPlanActionSearch;
      if (resultofRelation.result.length==0) {
        // 如果没有返回结果，说明没有计划与目标 Action 关联
        relationActionwithPlan = true;
      } else {
        // 如果有结果，说明计划与目标 Action 关联
        relationActionwithPlan = false;
      }
    })

    if(relationActionwithPlan){
      console.info(`There is a relationship between Plan and Action,fail to delete`);
      return false;
    }

    if(!issuccess){
      return false;
    }

    //调用云函数删除目标动作
    cloudFunction.call({
      name: 'action-bycyb-cloud-function',
      version: '$latest',
      timeout: 10 * 1000,
      data: {
        operation: 'deleteAction',
        records: actionID
      }
    }, (err: BusinessError, data: cloudFunction.FunctionResult) => {
      if (err) {
        console.error(`Failed to call the function, Code: ${err.code}, message: ${err.message}`);
        issuccess=false;
      }
      console.info(`Succeeded in calling the function, result: ${JSON.stringify(data.result)}`);

    })

    //判断前一次操作是否成功
    if(!issuccess){
      return false;
    }

    //调用云函数删除UserAction表中的关系
    cloudFunction.call({
      name: 'action-bycyb-cloud-function',
      version: '$latest',
      timeout: 10 * 1000,
      data: {
        operation: 'deleteUserAction',
        records: {"ActionID":actionID,"UserID":uid}
      }
    }, (err: BusinessError, data: cloudFunction.FunctionResult) => {
      if (err) {
        console.error(`Failed to call the function, Code: ${err.code}, message: ${err.message}`);
        issuccess=false;
      }
      console.info(`Succeeded in calling the function, result: ${JSON.stringify(data.result)}`);
    })

    //判断前一次操作是否成功
    if(!issuccess){
      return false;
    }

    return issuccess;
  }


 //查找用户自建动作
  async getMyAction(uid: string): Promise<Action[] | boolean> {
    try {
      // 第一个异步调用：获取用户的 ActionID 列表
      const data: cloudFunction.FunctionResult = await new Promise((resolve, reject) => {
        cloudFunction.call({
          name: 'action-bycyb-cloud-function',
          version: '$latest',
          timeout: 10 * 1000,
          data: {
            operation: 'queryActionByUserID',
            records: uid
          }
        }, (err: BusinessError, data: cloudFunction.FunctionResult) => {
          if (err) {
            console.error(`Failed to call the function, Code: ${err.code}, message: ${err.message}`);
            reject(false);  // 调用失败时返回 false
          } else {
            console.info(`Succeeded in calling the function, result: ${JSON.stringify(data.result)}`);
            resolve(data);  // 调用成功时返回 data
          }
        });
      });

      // 获取用户的 ActionID 列表并检查数据有效性
      const cfReturn = data.result as ResultofUserActionSearch;
      const userActions= cfReturn.result;
      if (!userActions || userActions.length == 0) {
        console.error('No actions found for the user.');
        return false;  // 如果没有找到用户的 Action，返回 false
      }


      const actionIDs = userActions.map(item => item.ActionID);

      // 使用 Promise.all 并行调用 queryActionByActionID 获取每个 Action
      const actions = await Promise.all(actionIDs.map(async (actionID) => {
        try {
          console.info("傻逼华为2");
          const result = await new Promise<Action | null>((resolve, reject) => {
            cloudFunction.call({
              name: 'action-bycyb-cloud-function',
              version: '$latest',
              timeout: 10 * 1000,
              data: {
                operation: 'queryActionByActionID',
                records: actionID
              }
            }, (err: BusinessError, data: cloudFunction.FunctionResult) => {
              if (err) {
                console.error(`Failed to call the function for ActionID: ${actionID}, Code: ${err.code}, message: ${err.message}`);
                reject(null);  // 如果失败，返回 null
              } else {
                console.info(`Succeeded in calling the function for ActionID: ${actionID}, result: ${JSON.stringify(data.result)}`);
                const resultofActionSearch=data.result as ResultofUserSingleActionSearch;
                resolve(resultofActionSearch.result);  // 成功时返回 Action 对象
              }
            });
          });

          return result ;  // 返回获取到的单个 Action 或 null

        } catch (error) {
          console.error(`Error fetching action for ActionID: ${actionID}:`, error);
          return null;  // 如果某个 Action 查询失败，返回 null
        }
      }));

      // 过滤掉为 null 的结果
      const validActions = actions.filter(action => action !== null) as Action[];

      if (validActions.length === 0) {
        console.error('No valid actions found.');
        return false;  // 如果没有有效的 Action，返回 false
      }

      // 返回所有的 Action 数组
      return validActions;

    } catch (error) {
      console.error('Error occurred:', error);
      return false;  // 捕获错误时返回 false
    }
  }


  //getAllAction()查找所有动作
  async getAllAction():Promise<Action[] | boolean>{
    try {
      const data: cloudFunction.FunctionResult = await new Promise((resolve, reject) => {
        cloudFunction.call({
          name: 'action-bycyb-cloud-function',
          version: '$latest',
          timeout: 10 * 1000,
          data: {
            operation: 'queryAllAction',
          }
        }, (err: BusinessError, data: cloudFunction.FunctionResult) => {
          if (err) {
            console.error(`Failed to call the function, Code: ${err.code}, message: ${err.message}`);
            reject(false);  // Reject with false or any relevant error information
          } else {
            console.info(`Succeeded in calling the function, result: ${JSON.stringify(data.result)}`);
            resolve(data);  // Resolve with the data from the cloud function
          }
        });
      });

      // 处理查询结果并返回
      const cfReturn = data.result as ResultofActionSearch;
      return cfReturn.result;

    } catch (error) {
      // 捕获错误并返回 false
      console.error('Error occurred:', error);
      return false;
    }
  }
}
