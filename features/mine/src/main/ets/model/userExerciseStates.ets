export class UserExerciseStates {
  private _totalSteps: number;
  private _totalExerciseTime: number;
  private _totalCaloriesBurned: number;
  private _timeStamp: Date;

  private constructor(
    totalSteps: number,
    totalExerciseTime: number,
    totalCaloriesBurned: number,
    timeStamp: Date
  ) {
    this._totalSteps = Math.max(0, totalSteps);
    this._totalExerciseTime = Math.max(0, totalExerciseTime);
    this._totalCaloriesBurned = Math.max(0, totalCaloriesBurned);
    this.timeStamp = timeStamp; // use setter for validation
  }

  // 工厂方法
  public static create(data: {
    totalSteps: number;
    totalExerciseTime: number;
    totalCaloriesBurned: number;
    timeStamp: Date;
  }): UserExerciseStates {
    return new UserExerciseStates(
      data.totalSteps,
      data.totalExerciseTime,
      data.totalCaloriesBurned,
      data.timeStamp
    );
  }

  public get totalSteps(): number {
    return this._totalSteps;
  }

  public set totalSteps(value: number) {
    this._totalSteps = Math.max(0, value);
  }

  public get totalExerciseTime(): number {
    return this._totalExerciseTime;
  }

  public set totalExerciseTime(value: number) {
    this._totalExerciseTime = Math.max(0, value);
  }

  public get totalCaloriesBurned(): number {
    return this._totalCaloriesBurned;
  }

  public set totalCaloriesBurned(value: number) {
    this._totalCaloriesBurned = Math.max(0, value);
  }

  public get timeStamp(): Date {
    return this._timeStamp;
  }

  public set timeStamp(value: Date) {
    if (!(value instanceof Date) || isNaN(value.getTime())) {
      throw new Error("Invalid date provided to timeStamp");
    }
    this._timeStamp = value;
  }

  // 用于序列化输出
  public toJSON() {
    return {
      totalSteps: this._totalSteps,
      totalExerciseTime: this._totalExerciseTime,
      totalCaloriesBurned: this._totalCaloriesBurned,
      timeStamp: this._timeStamp.toISOString(),
    };
  }
}
