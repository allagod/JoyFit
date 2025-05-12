export default class Badge {
  imageUrl: string = ''
  description: string = ''
  name: string = ''
  time: string = ''

  constructor(imageUrl: string, description: string, name: string, time: string) {
    this.imageUrl = imageUrl
    this.description = description
    this.name = name
    this.time = time
  }
}
