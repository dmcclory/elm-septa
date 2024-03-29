import './main.css';
import { Elm } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

Elm.Main.init({
  node: document.getElementById('root'),
  dimensions: { height: window.outerHeight, width: window.outerWidth }
});

registerServiceWorker();
