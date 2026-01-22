import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    reminderId: Number,
    dayId: Number,
    listId: Number
  }

  // This controller is attached to the actions sheet
  // It doesn't need any methods since move up/down are handled via forms
  // But we keep it for consistency with note-move controller structure
}
