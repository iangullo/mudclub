// app/javascript/controllers/match_location_controller.js
// Manages autoselection of homecourts for matches depending on local/away and team names.
// Assistance from ChatGPT tweaking behaviour!
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["homeRadio", "homeCourtId", "locationId", "rivalName"];

  connect() {
    //console.log("this.homeCourtId => ", this.homeCourtIdTarget.value)
    this.homeCourts = JSON.parse(this.rivalNameTarget.dataset.homecourts);
    //console.log("this.homeCourts => ", this.homeCourts)
    // Gather all options from the datalist directly
    const dataList = document.getElementById("name_list");
    this.rivalList = Array.from(dataList.options).map(option => option.value.trim());
    //console.log("this.rivalList => ", this.rivalList)
    this.selectHomeCourt();
  }

  selectHomeCourt() {
    const isHomeMatch = this.homeRadioTarget.checked;
    //console.log("selectHomeCourt(isHomeMatch=,", isHomeMatch, ", rivalName='",this.rivalNameTarget.value,"')")

    // Set location select to home court if it's a home match
    if (isHomeMatch && this.homeCourtIdTarget) {
      //console.log("homeGame. Should set location to:", this.homeCourtIdTarget.value)
      this.locationIdTarget.value = this.homeCourtIdTarget.value;
    }
    
    // Check if it's an away match and rival name has a match in the datalist
    if (!isHomeMatch && this.rivalNameTarget.value) {
      const rivalName = this.rivalNameTarget.value.trim().toLowerCase(); // Convert to lowercase for case insensitivity
      const index = this.rivalList.findIndex(option => option.toLowerCase() === rivalName); // Find the index case insensitively
      //console.log("rivalName='",rivalName,"' has index=",index)
      //console.log("awayGame. Should set location to:", this.homeCourts[index])

      // Set location select to the corresponding home court if needed
      if (index !== -1) {
        this.locationIdTarget.value = this.homeCourts[index];
        this.rivalNameTarget.value = this.rivalList[index]; // Replace textbox value with the matched string
      }
    }
    //console.log("this.locationId => ", this.locationIdTarget.value)
  }

  // Listen for changes in the rival name input field
  onChange() {
    this.selectHomeCourt();
  }
}