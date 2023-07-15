import Chart from "chart.js/auto";
import ChartDataLabels from "chartjs-plugin-datalabels";

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

    this.chart = new Chart(this.el, {
      type: "pie",
      data: {
        labels: categoryNames,
        datasets: [
          {
            label: "Expenses",
            data: categoryCosts,
            backgroundColor: [
              "rgba(255, 99, 132, 0.2)",
              "rgba(54, 162, 235, 0.2)",
              "rgba(255, 206, 86, 0.2)",
            ],
            borderColor: [
              "rgba(255, 99, 132, 1)",
              "rgba(54, 162, 235, 1)",
              "rgba(255, 206, 86, 1)",
            ],
            borderWidth: 1,
          },
        ],
      },
      options: {
        responsive: true,
        legend: {
          position: "top",
        },
        title: {
          display: true,
          text: "Expenses by Category",
        },
        animation: {
          animateScale: true,
          animateRotate: true,
        },
      },
    });
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

    this.chart = new Chart(this.el, {
      type: "pie",
      data: {
        labels: categoryNames,
        datasets: [
          {
            label: "Expenses",
            data: categoryCosts,
            backgroundColor: [
              "rgba(255, 99, 132, 0.2)",
              "rgba(54, 162, 235, 0.2)",
              "rgba(255, 206, 86, 0.2)",
            ],
            borderColor: [
              "rgba(255, 99, 132, 1)",
              "rgba(54, 162, 235, 1)",
              "rgba(255, 206, 86, 1)",
            ],
            borderWidth: 1,
          },
        ],
      },
      options: {
        responsive: true,
        legend: {
          position: "top",
        },
        title: {
          display: true,
          text: "Expenses by Category",
        },
        animation: {
          animateScale: true,
          animateRotate: true,
        },
      },
    });
  },

  destroyed() {
    this.chart.destroy();
  },
};
