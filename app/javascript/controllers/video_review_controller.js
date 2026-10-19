// app/javascript/controllers/video_review_controller.js
// Match video review: clicking a tagged moment plays the embedded YouTube video from that second.
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["player"];
  static values = { id: String };

  seek({ params: { second } }) {
    if (!this.hasPlayerTarget || !this.idValue) return;

    this.playerTarget.src = `https://www.youtube-nocookie.com/embed/${this.idValue}?rel=0&autoplay=1&start=${second}`;
    this.playerTarget.scrollIntoView({ behavior: "smooth", block: "nearest" });
  }
}
