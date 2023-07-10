import Chart from "chart.js/auto";
import ChartDataLabels from 'chartjs-plugin-datalabels';
import { categoryColors, getYearMonth } from "../helpers";

Chart.register(ChartDataLabels);

export default {
  mounted() {
    const budgets = JSON.parse(this.el.dataset.budgets);

    const groupedData = budgets.reduce((acc, curr) => {
      const yearMonth = getYearMonth(curr.created_at);
      if (!acc[yearMonth]) {
        acc[yearMonth] = {};
      }
      if (!acc[yearMonth][curr.category]) {
        acc[yearMonth][curr.category] = 0;
      }
      acc[yearMonth][curr.category] += curr.cost;
      return acc;
    }, {});
    
    const categories = [...new Set(budgets.map(budget => budget.category))];
    const sortedDates = Object.keys(groupedData).sort((a, b) => new Date(a) - new Date(b));

    const datasets = categories.map(category => {
      return {
        label: category,
        data: sortedDates.map(date => groupedData[date][category] || 0),
        backgroundColor: categoryColors[category].backgroundColor,
        borderColor: categoryColors[category].borderColor,
        borderWidth: 1
      };
    });

    const formatter = (value, ctx) => {
      const stackedValues = ctx.chart.data.datasets
        .map((ds) => ds.data[ctx.dataIndex]);
      const dsIdxLastVisibleNonZeroValue = stackedValues
        .reduce((prev, curr, i) => !!curr && !ctx.chart.getDatasetMeta(i).hidden ? Math.max(prev, i) : prev, 0);
      if (!!value && ctx.datasetIndex === dsIdxLastVisibleNonZeroValue) {
        return stackedValues
          .filter((ds, i) => !ctx.chart.getDatasetMeta(i).hidden)
          .reduce((sum, v) => sum + v, 0);
      } else {
        return "";
      }
    };
    
    this.chart = new Chart(
      this.el,
      {
        type: 'bar',
        data: {
          labels: sortedDates,
          datasets: datasets
        },
        options: {
          plugins: {
            datalabels: {
              align: 'top',
              anchor: 'end',
              formatter,
            }
          },
          scales: {
            x: {
              stacked: true
            },
            y: { stacked: true, ticks: { stepSize: 1000 }, min: 0, max: 400000 }
          },
        },
        tooltips: {
          mode: 'label',
          callbacks: {
          }
        },
      },
    );
  },

  destroyed() {
    this.chart.destroy();
  }
};
