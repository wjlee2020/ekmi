export { default as categoryColors } from './constants';

const categoryColors = {
  "Rent": "#4287F5",
  "Groceries/Food": "#F7630C",
  "Utilities": "#28B463",
  "Transportation": "#FFCE56",
  "Entertainment": "#9966FF",
  "Misc./Hobby": "#FF6666",
}

export function getYearMonth(dateStr) {
  const date = new Date(dateStr);
  const year = date.getFullYear();
  const month = date.getMonth();
  return `${year}-${month < 9 ? '0' : ''}${month + 1}`;
};

export function jpyCurrency(value) {
  return new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY' }).format(value);
}

export function formatter(value, ctx) {
  const stackedValues = ctx.chart.data.datasets
    .map((ds) => ds.data[ctx.dataIndex]);
  const dsIdxLastVisibleNonZeroValue = stackedValues
    .reduce((prev, curr, i) => !!curr && !ctx.chart.getDatasetMeta(i).hidden ? Math.max(prev, i) : prev, 0);

  if (!!value && ctx.datasetIndex === dsIdxLastVisibleNonZeroValue) {
    return jpyCurrency(stackedValues
      .filter((ds, i) => !ctx.chart.getDatasetMeta(i).hidden)
      .reduce((sum, v) => sum + v, 0));
  } else {
    return "";
  }
};

export function chartConfig(categoryNames, categoryCosts) {
  return {
    type: "pie",
    data: {
      labels: categoryNames,
      datasets: [
        {
          label: "Expenses",
          data: categoryCosts,
          backgroundColor: categoryNames.map(name => categoryColors[name]),
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
  };
}
