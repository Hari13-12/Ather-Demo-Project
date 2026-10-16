import { LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { refreshApex } from "@salesforce/apex";
import getConsoleData from "@salesforce/apex/LeadPriorityConsoleController.getConsoleData";

const ALL_VALUE = "__all__";

export default class LeadPriorityConsole extends NavigationMixin(
  LightningElement
) {
  data;
  errorMessage;
  isRefreshing = false;
  searchTerm = "";
  selectedSource = ALL_VALUE;
  selectedStatus = ALL_VALUE;
  selectedLeadId;
  wiredResult;

  @wire(getConsoleData)
  wiredConsoleData(result) {
    this.wiredResult = result;
    const { data, error } = result;
    if (data) {
      this.data = data;
      this.errorMessage = data.dependencyAvailable
        ? undefined
        : data.errorMessage;
      this.selectedLeadId = data.highPriorityLeads?.some(
        (lead) => lead.id === this.selectedLeadId
      )
        ? this.selectedLeadId
        : data.highPriorityLeads?.[0]?.id;
    } else if (error) {
      this.data = undefined;
      this.errorMessage =
        "Unable to load Lead Priority data. Please refresh and try again.";
    }
    this.isRefreshing = false;
  }

  get isLoading() {
    return !this.data && !this.errorMessage;
  }

  get hasDependencyError() {
    return this.data && !this.data.dependencyAvailable;
  }

  get highPriorityLeads() {
    return this.data?.highPriorityLeads || [];
  }

  get filteredLeads() {
    const search = this.searchTerm.trim().toLowerCase();
    return this.highPriorityLeads.filter((lead) => {
      const matchesSearch =
        !search ||
        (lead.name || "").toLowerCase().includes(search) ||
        (lead.company || "").toLowerCase().includes(search);
      const matchesSource =
        this.selectedSource === ALL_VALUE ||
        (lead.leadSource || "") === this.selectedSource;
      const matchesStatus =
        this.selectedStatus === ALL_VALUE ||
        lead.status === this.selectedStatus;
      return matchesSearch && matchesSource && matchesStatus;
    });
  }

  get sourceOptions() {
    return this.createOptions(
      this.highPriorityLeads.map((lead) => lead.leadSource || ""),
      "Other / Blank"
    );
  }

  get statusOptions() {
    return this.createOptions(
      this.highPriorityLeads.map((lead) => lead.status),
      "Blank"
    );
  }

  get selectedLead() {
    return this.highPriorityLeads.find(
      (lead) => lead.id === this.selectedLeadId
    );
  }

  get hasLeads() {
    return this.highPriorityLeads.length > 0;
  }

  get hasFilteredLeads() {
    return this.filteredLeads.length > 0;
  }

  createOptions(values, blankLabel) {
    const options = [...new Set(values)].sort().map((value) => ({
      label: value || blankLabel,
      value
    }));
    return [{ label: "All", value: ALL_VALUE }, ...options];
  }

  handleSearch(event) {
    this.searchTerm = event.target.value;
  }

  handleSourceChange(event) {
    this.selectedSource = event.detail.value;
  }

  handleStatusChange(event) {
    this.selectedStatus = event.detail.value;
  }

  handleRowSelect(event) {
    this.selectedLeadId = event.currentTarget.dataset.id;
  }

  handleRowKeydown(event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      this.handleRowSelect(event);
    }
  }

  navigateToLead(event) {
    event.stopPropagation();
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: event.currentTarget.dataset.id,
        objectApiName: "Lead",
        actionName: "view"
      }
    });
  }

  async handleRefresh() {
    this.isRefreshing = true;
    try {
      await refreshApex(this.wiredResult);
    } catch (error) {
      this.errorMessage =
        "Unable to load Lead Priority data. Please refresh and try again.";
      this.isRefreshing = false;
    }
  }
}
