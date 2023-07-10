export { default as categoryColors } from './constants';

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
