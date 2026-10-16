import { createElement } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { registerApexTestWireAdapter } from "@salesforce/sfdx-lwc-jest";
import LeadPriorityConsole from "c/leadPriorityConsole";
import getConsoleData from "@salesforce/apex/LeadPriorityConsoleController.getConsoleData";

jest.mock(
  "@salesforce/apex",
  () => ({ refreshApex: jest.fn(() => Promise.resolve()) }),
  { virtual: true }
);

const mockNavigateSymbol = Symbol("Navigate");
const mockNavigate = jest.fn();
jest.mock(
  "lightning/navigation",
  () => {
    const NavigationMixin = (Base) =>
      class extends Base {
        [mockNavigateSymbol](pageReference) {
          mockNavigate(pageReference);
        }
      };
    NavigationMixin.Navigate = mockNavigateSymbol;
    return { NavigationMixin };
  },
  { virtual: true }
);

const getConsoleDataAdapter = registerApexTestWireAdapter(getConsoleData);
const flushPromises = () => Promise.resolve();
const consoleData = {
  dependencyAvailable: true,
  priorityRuleCount: 2,
  highPriorityTodayCount: 1,
  defaultPriority: "Normal",
  ruleMappings: [
    { leadSource: "Web", priority: "High", mappingKey: "Web-High" },
    {
      leadSource: "Web",
      priority: "Normal",
      mappingKey: "Web-Normal"
    }
  ],
  highPriorityLeads: [
    {
      id: "00Q000000000001AAA",
      name: "Ada Web",
      company: "Acme",
      leadSource: "Web",
      priority: "High",
      status: "New",
      ownerName: "Owner One"
    },
    {
      id: "00Q000000000002AAA",
      name: "Blank Source",
      company: null,
      leadSource: null,
      priority: "High",
      status: "Working",
      ownerName: "Owner Two"
    }
  ]
};

function createComponent(data = consoleData) {
  const element = createElement("c-lead-priority-console", {
    is: LeadPriorityConsole
  });
  document.body.appendChild(element);
  getConsoleDataAdapter.emit(data);
  return element;
}

describe("c-lead-priority-console", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("filters rows by search, source, and status while displaying blank values safely", async () => {
    const element = createComponent();
    await flushPromises();

    let rows = element.shadowRoot.querySelectorAll("tbody tr");
    expect(rows).toHaveLength(4);
    expect(element.shadowRoot.textContent).toContain("Other / Blank");
    expect(element.shadowRoot.textContent).toContain("—");

    const search = element.shadowRoot.querySelector("lightning-input");
    search.value = "Ada";
    search.dispatchEvent(new CustomEvent("change"));
    await flushPromises();
    expect(element.shadowRoot.querySelectorAll("tbody tr")).toHaveLength(3);

    const filters = element.shadowRoot.querySelectorAll("lightning-combobox");
    filters[0].dispatchEvent(
      new CustomEvent("change", { detail: { value: "Web" } })
    );
    filters[1].dispatchEvent(
      new CustomEvent("change", { detail: { value: "New" } })
    );
    await flushPromises();
    rows = element.shadowRoot.querySelectorAll("tbody tr");
    expect(rows).toHaveLength(3);
    expect(rows[2].textContent).toContain("Ada Web");
  });

  it("selects a table row and navigates with the NavigationMixin", async () => {
    const element = createComponent();
    await flushPromises();

    const rows = element.shadowRoot.querySelectorAll("tbody tr");
    rows[3].click();
    await flushPromises();
    expect(element.shadowRoot.textContent).toContain("Blank Source");

    element.shadowRoot.querySelector(".link-button").click();
    expect(mockNavigate).toHaveBeenCalledWith({
      type: "standard__recordPage",
      attributes: {
        recordId: "00Q000000000001AAA",
        objectApiName: "Lead",
        actionName: "view"
      }
    });
  });

  it("refreshes the wired data", async () => {
    const element = createComponent();
    await flushPromises();
    element.shadowRoot.querySelector("lightning-button").click();
    await flushPromises();
    expect(refreshApex).toHaveBeenCalled();
  });

  it("shows empty, dependency, and server error states", async () => {
    const element = createComponent({
      ...consoleData,
      highPriorityLeads: []
    });
    await flushPromises();
    expect(element.shadowRoot.textContent).toContain(
      "No High Priority Leads found."
    );

    getConsoleDataAdapter.emit({
      dependencyAvailable: false,
      errorMessage: "Lead Priority is unavailable.",
      highPriorityLeads: []
    });
    await flushPromises();
    expect(element.shadowRoot.textContent).toContain(
      "Lead Priority is unavailable."
    );

    getConsoleDataAdapter.error();
    await flushPromises();
    expect(element.shadowRoot.textContent).toContain(
      "Unable to load Lead Priority data. Please refresh and try again."
    );
  });
});
