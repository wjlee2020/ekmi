// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import Chart from 'chart.js/auto'

let Hooks = {};

Hooks.Chart = {
  mounted() {
    const budgets = JSON.parse(this.el.dataset.budgets);

    const groupedData = budgets.reduce((acc, curr) => {
      if (!acc[curr.created_at]) {
        acc[curr.created_at] = {};
      }

      if (!acc[curr.created_at][curr.category]) {
        acc[curr.created_at][curr.category] = 0;
      }

      acc[curr.created_at][curr.category] += curr.cost;
      return acc;
    }, {});

    const categoryColors = {
      'Rent': { 
        backgroundColor: 'rgba(75, 192, 192, 0.2)', 
        borderColor: 'rgba(75, 192, 192, 1)' 
      },
      'Groceries/Food': { 
        backgroundColor: 'rgba(255, 99, 132, 0.2)', 
        borderColor: 'rgba(255, 99, 132, 1)' 
      },
      'Transportation': { 
        backgroundColor: 'rgba(255, 205, 86, 0.2)', 
        borderColor: 'rgba(255, 205, 86, 1)' 
      },
      'Utilities': { 
        backgroundColor: 'rgba(54, 162, 235, 0.2)', 
        borderColor: 'rgba(54, 162, 235, 1)' 
      },
      'Entertainment': { 
        backgroundColor: 'rgba(153, 102, 255, 0.2)', 
        borderColor: 'rgba(153, 102, 255, 1)' 
      },
      'Misc./Hobby': { 
        backgroundColor: 'rgba(201, 203, 207, 0.2)', 
        borderColor: 'rgba(201, 203, 207, 1)' 
      },
    };
    
    
    
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
    
    this.chart = new Chart(
      this.el,
      {
        type: 'bar',
        data: {
          labels: sortedDates,
          datasets: datasets
        },
        options: {
          scales: {
            x: {
              stacked: true
            },
            y: { stacked: true, ticks: { stepSize: 1000 }, min: 0, max: 400000 }
          },
        },
      },
    );
  },

  destroyed() {
    this.chart.destroy();
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

