// app/javascript/controllers/video_review_controller.js
// Match video review: clicking a tagged moment plays the match video from that second,
// either an uploaded file (<video>) or an embedded YouTube video (<iframe>).
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["video", "player"];
  static values = { id: String };

  seek({ params: { second } }) {
    if (this.hasVideoTarget) {
      this.videoTarget.currentTime = second;
      this.videoTarget.play();
      this.videoTarget.scrollIntoView({ behavior: "smooth", block: "nearest" });
    } else if (this.hasPlayerTarget && this.idValue) {
      this.playerTarget.src = `https://www.youtube-nocookie.com/embed/${this.idValue}?rel=0&autoplay=1&start=${second}`;
      this.playerTarget.scrollIntoView({ behavior: "smooth", block: "nearest" });
    }
  }
}
