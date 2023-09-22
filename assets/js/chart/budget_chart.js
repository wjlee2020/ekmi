import Chart from "chart.js/auto";
import ChartDataLabels from "chartjs-plugin-datalabels";
import { chartConfig } from "../helpers";

Chart.register(ChartDataLabels);

export default {
  mounted() {
    const budgets = JSON.parse(this.el.dataset.budgets);

    const categories = budgets.reduce((accumulator, item) => {
      accumulator[item.category] =
        (accumulator[item.category] || 0) + item.cost;
      return accumulator;
    }, {});

    const categoryNames = Object.keys(categories);
    const categoryCosts = Object.values(categories);

    this.chart = new Chart(this.el, chartConfig(categoryNames, categoryCosts));
  },

  updated() {
    this.chart.destroy();

    const budgets = JSON.parse(this.el.dataset.budgets);

    const categories = budgets.reduce((accumulator, item) => {
      accumulator[item.category] =
        (accumulator[item.category] || 0) + item.cost;
      return accumulator;
    }, {});

    const categoryNames = Object.keys(categories);
    const categoryCosts = Object.values(categories);

    this.chart = new Chart(this.el, chartConfig(categoryNames, categoryCosts));
  },

  destroyed() {
    this.chart.destroy();
  },
};
