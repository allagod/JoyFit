import { cloudDatabase } from '@kit.CloudFoundationKit';

// 创建一个 RunningRecord 类，继承 cloudDatabase.DatabaseObject
class RunningRecord extends cloudDatabase.DatabaseObject {
  // 返回类名，供 Cloud DB 使用
  naturalbase_ClassName() {
    return 'RunningRecord';
  }

  constructor() {
    super();
    this.RecordID = undefined;   // Integer 类型
    this.Image = undefined;      // String 类型
    this.Feeling = undefined;    // Text 类型
    this.RecordDate = undefined; // Date 类型
    this.Calories = undefined;   // Double 类型
    this.PlanID = undefined;     // Integer 类型
    this.Speed = undefined;      // Double 类型
    this.Miles = undefined;      // Double 类型
    this.TotalTime = undefined;  // Double 类型
    this.Location = undefined;   // String 类型
  }
}

export { RunningRecord };
