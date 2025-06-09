import { cloudDatabase } from "@kit.CloudFoundationKit";
import { PlanTask } from "../bean/PlanTask";
import { RunningRecord } from "../bean/RunningRecord";
import { WorkoutRecord } from "../bean/WorkoutRecord";

export class RecordService {
  private static instance: RecordService | null = null;
  private agcDataBase: cloudDatabase.DatabaseZone = cloudDatabase.zone('joyfit');

  private constructor() {}

  public static getInstance(): RecordService {
    if (!RecordService.instance) {
      RecordService.instance = new RecordService();
    }
    return RecordService.instance;
  }

  /**
   * 获取某计划下的训练或跑步感受记录
   */
  public async getFeelingsByPlan(userID: string, planID: string, type: string) {
    const recordClass = this.getRecordModel(type);
    if (!recordClass) return [];

    const condition = new cloudDatabase.DatabaseQuery(recordClass);
    condition.equalTo('UserID', userID).and().equalTo('PlanID', planID);
    return await this.agcDataBase.query(condition);
  }

  /**
   * 获取某个计划下的任务记录
   */
  public async getRecords(userID: string, planID: string, type: string) {
    const taskType = this.getTaskType(type);
    if (!taskType) return [];

    const condition = new cloudDatabase.DatabaseQuery(PlanTask);
    condition.equalTo('UserID', userID)
      .and().equalTo('PlanID', planID)
      .and().equalTo('TaskType', taskType);
    return await this.agcDataBase.query(condition);
  }

  /**
   * 添加训练或跑步记录
   */
  public async addRecord(record: WorkoutRecord | RunningRecord): Promise<boolean> {
    try {
      await this.agcDataBase.upsert(record);
      return true;
    } catch (error) {
      console.error("Failed to add record:", error);
      return false;
    }
  }

  /**
   * 更新指定记录
   */
  public async updateRecord(recordID: string, data: Partial<WorkoutRecord | RunningRecord>, type: string): Promise<boolean> {
    const recordClass = this.getRecordModel(type);
    if (!recordClass) return false;

    try {
      const query = new cloudDatabase.DatabaseQuery(recordClass).equalTo('id', recordID);
      const result = await this.agcDataBase.query(query);

      if (result.length === 0) return false;

      const recordToUpdate = Object.assign(result[0], data);
      await this.agcDataBase.upsert(recordToUpdate);
      return true;
    } catch (error) {
      console.error("Failed to update record:", error);
      return false;
    }
  }

  /**
   * 删除指定记录
   */
  public async deleteRecord(recordID: string, type: string): Promise<boolean> {
    const recordClass = this.getRecordModel(type);
    if (!recordClass) return false;

    try {
      const query = new cloudDatabase.DatabaseQuery(recordClass).equalTo('id', recordID);
      const result = await this.agcDataBase.query(query);
      if (result.length === 0) return false;

      await this.agcDataBase.delete(result[0]);
      return true;
    } catch (error) {
      console.error("Failed to delete record:", error);
      return false;
    }
  }

  /**
   * 获取用户最近 N 条记录（按时间倒序）
   */
  public async getRecentRecords(userID: string, type: string, limit: number = 5) {
    const recordClass = this.getRecordModel(type);
    if (!recordClass) return [];

    const query = new cloudDatabase.DatabaseQuery(recordClass)
      .equalTo('UserID', userID)
      .orderByDesc('CreateTime')
      .limit(limit);

    return await this.agcDataBase.query(query);
  }

  /**
   * 获取某时间范围内的记录
   */
  public async getRecordsByDateRange(userID: string, type: string, startDate: Date, endDate: Date) {
    const recordClass = this.getRecordModel(type);
    if (!recordClass) return [];

    const query = new cloudDatabase.DatabaseQuery(recordClass)
      .equalTo('UserID', userID)
      .greaterThanOrEqualTo('CreateTime', startDate)
      .and().lessThanOrEqualTo('CreateTime', endDate);

    return await this.agcDataBase.query(query);
  }

  /**
   * 获取记录数据模型（根据类型）
   */
  private getRecordModel(type: string) {
    if (type === 'workout') return WorkoutRecord;
    if (type === 'running') return RunningRecord;
    return null;
  }

  /**
   * 获取任务类型字段（用于 PlanTask 查询）
   */
  private getTaskType(type: string) {
    if (type === 'workout' || type === 'running') return type;
    return null;
  }
}


  /**
   * 判断某条记录是否已存在（避免重复记录）
   */
  public async isRecordExists(userID: string, planID: string, type: string, date: Date): Promise<boolean> {
    const recordClass = this.getRecordModel(type);
    if (!recordClass) return false;

    const query = new cloudDatabase.DatabaseQuery(recordClass)
      .equalTo('UserID', userID)
      .and().equalTo('PlanID', planID)
      .and().equalTo('RecordDate', date);

    const result = await this.agcDataBase.query(query);
    return result.length > 0;
  }

  /**
   * 获取用户在某个计划下的记录数量
   */
  public async countRecordsByPlan(userID: string, planID: string, type: string): Promise<number> {
    const recordClass = this.getRecordModel(type);
    if (!recordClass) return 0;

    const query = new cloudDatabase.DatabaseQuery(recordClass)
      .equalTo('UserID', userID)
      .and().equalTo('PlanID', planID);

    const result = await this.agcDataBase.query(query);
    return result.length;
  }

  /**
   * 获取某个字段的最大值（例如最大心率、最大步数）
   */
  public async getMaxFieldValue(userID: string, type: string, fieldName: string): Promise<number | null> {
    const recordClass = this.getRecordModel(type);
    if (!recordClass) return null;

    const query = new cloudDatabase.DatabaseQuery(recordClass)
      .equalTo('UserID', userID)
      .orderByDesc(fieldName)
      .limit(1);

    const result = await this.agcDataBase.query(query);
    if (result.length > 0 && result[0][fieldName] !== undefined) {
      return result[0][fieldName];
    }
    return null;
  }

  /**
   * 批量添加多条记录（用于批量导入等）
   */
  public async addMultipleRecords(records: (WorkoutRecord | RunningRecord)[]): Promise<boolean> {
    try {
      for (const record of records) {
        await this.agcDataBase.upsert(record);
      }
      return true;
    } catch (err) {
      console.error("Failed to add multiple records:", err);
      return false;
    }
  }

  /**
   * 分页查询用户历史记录
   */
  public async getRecordsPaginated(userID: string, type: string, page: number = 1, pageSize: number = 10) {
    const recordClass = this.getRecordModel(type);
    if (!recordClass) return [];

    const offset = (page - 1) * pageSize;
    const query = new cloudDatabase.DatabaseQuery(recordClass)
      .equalTo('UserID', userID)
      .orderByDesc('CreateTime')
      .limit(pageSize)
      .offset(offset);

    return await this.agcDataBase.query(query);
  }

  /**
   * 按日期分组统计每天的记录数量（如用于图表）
   */
  public async groupRecordsByDate(userID: string, type: string): Promise<{ [date: string]: number }> {
    const recordClass = this.getRecordModel(type);
    if (!recordClass) return {};

    const query = new cloudDatabase.DatabaseQuery(recordClass)
      .equalTo('UserID', userID)
      .orderByDesc('CreateTime');

    const result = await this.agcDataBase.query(query);
    const grouped: { [date: string]: number } = {};

    result.forEach((record: any) => {
      const date = new Date(record.CreateTime).toISOString().split('T')[0]; // 格式: yyyy-mm-dd
      if (!grouped[date]) {
        grouped[date] = 0;
      }
      grouped[date]++;
    });

    return grouped;
  }


  private agcDataBase = cloudDatabase.zone('joyfit');

  /**
   * 导出某用户某计划的所有记录为JSON字符串，方便导出备份
   */
  public async exportRecordsAsJSON(userID: string, planID: string, type: string): Promise<string> {
    const recordClass = this.getRecordModel(type);
    if (!recordClass) return "[]";

    const query = new cloudDatabase.DatabaseQuery(recordClass)
      .equalTo('UserID', userID)
      .and().equalTo('PlanID', planID);

    const records = await this.agcDataBase.query(query);
    return JSON.stringify(records);
  }

  /**
   * 批量导入记录，传入JSON数组字符串，会自动解析并插入
   */
  public async importRecordsFromJSON(jsonStr: string, type: string): Promise<boolean> {
    try {
      const records = JSON.parse(jsonStr);
      if (!Array.isArray(records)) return false;

      const recordClass = this.getRecordModel(type);
      if (!recordClass) return false;

      for (const recData of records) {
        const record = Object.assign(new recordClass(), recData);
        await this.agcDataBase.upsert(record);
      }
      return true;
    } catch (e) {
      console.error("导入记录失败:", e);
      return false;
    }
  }

  /**
   * 切换记录状态（如暂停<->进行中），方便快速操作
   */
  public async toggleRecordStatus(recordID: string, type: string): Promise<boolean> {
    const recordClass = this.getRecordModel(type);
    if (!recordClass) return false;

    try {
      const query = new cloudDatabase.DatabaseQuery(recordClass).equalTo('id', recordID);
      const results = await this.agcDataBase.query(query);
      if (results.length === 0) return false;

      const record = results[0];
      record.Status = record.Status === 'paused' ? 'inProgress' : 'paused';
      await this.agcDataBase.upsert(record);
      return true;
    } catch (e) {
      console.error("切换记录状态失败:", e);
      return false;
    }
  }

  /**
   * 校验记录数据是否完整，字段是否符合预期（示例：心率、步数非负）
   */
  public validateRecordData(record: RunningRecord | WorkoutRecord): boolean {
    if (record.HeartRate != null && record.HeartRate < 0) return false;
    if (record.StepCount != null && record.StepCount < 0) return false;
    if (record.Duration != null && record.Duration <= 0) return false;
    // 可根据业务继续扩展校验规则
    return true;
  }

  /**
   * 根据多个条件复合筛选记录（示例：时间区间 + 最小心率 + 最大步数）
   */
  public async filterRecordsAdvanced(userID: string, type: string, options: {
    startDate?: Date,
    endDate?: Date,
    minHeartRate?: number,
    maxStepCount?: number
  }): Promise<(RunningRecord | WorkoutRecord)[]> {
    const recordClass = this.getRecordModel(type);
    if (!recordClass) return [];

    const query = new cloudDatabase.DatabaseQuery(recordClass).equalTo('UserID', userID);

    if (options.startDate) {
      query.greaterThanOrEqualTo('CreateTime', options.startDate);
    }
    if (options.endDate) {
      query.and().lessThanOrEqualTo('CreateTime', options.endDate);
    }
    if (options.minHeartRate != null) {
      query.and().greaterThanOrEqualTo('HeartRate', options.minHeartRate);
    }
    if (options.maxStepCount != null) {
      query.and().lessThanOrEqualTo('StepCount', options.maxStepCount);
    }

    return await this.agcDataBase.query(query);
  }

  /**
   * 计算用户最近7天每天的训练时长趋势，返回时间轴和对应的时长数据
   */
  public async getWeeklyDurationTrend(userID: string, type: string): Promise<{ dates: string[], durations: number[] }> {
    const recordClass = this.getRecordModel(type);
    if (!recordClass) return { dates: [], durations: [] };

    const now = new Date();
    const dates: string[] = [];
    const durations: number[] = [];

    for (let i = 6; i >= 0; i--) {
      const dayStart = new Date(now);
      dayStart.setHours(0, 0, 0, 0);
      dayStart.setDate(dayStart.getDate() - i);

      const dayEnd = new Date(dayStart);
      dayEnd.setHours(23, 59, 59, 999);

      const query = new cloudDatabase.DatabaseQuery(recordClass)
        .equalTo('UserID', userID)
        .greaterThanOrEqualTo('CreateTime', dayStart)
        .and().lessThanOrEqualTo('CreateTime', dayEnd);

      const records = await this.agcDataBase.query(query);
      const totalDuration = records.reduce((sum, r) => sum + (r.Duration || 0), 0);

      dates.push(dayStart.toISOString().slice(0, 10));
      durations.push(totalDuration);
    }

    return { dates, durations };
  }

  /**
   * 计算用户活跃度：最近30天有记录的天数
   */
  public async getUserActiveDaysLast30(userID: string, type: string): Promise<number> {
    const recordClass = this.getRecordModel(type);
    if (!recordClass) return 0;

    const now = new Date();
    const startDate = new Date();
    startDate.setDate(now.getDate() - 30);

    const query = new cloudDatabase.DatabaseQuery(recordClass)
      .equalTo('UserID', userID)
      .greaterThanOrEqualTo('CreateTime', startDate);

    const records = await this.agcDataBase.query(query);
    const activeDaysSet = new Set<string>();

    records.forEach(record => {
      const day = new Date(record.CreateTime).toISOString().slice(0, 10);
      activeDaysSet.add(day);
    });

    return activeDaysSet.size;
  }

  /**
   * 私有方法，根据type获取对应的记录数据模型类
   */
  private getRecordModel(type: string) {
    if (type === 'workout') return WorkoutRecord;
    if (type === 'running') return RunningRecord;
    return null;
  }
