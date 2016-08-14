# Shared Matting WebGL implementation
Implement Shared Sampling for Real-Time Alpha Matting using webgl shader language(glsl). [Paper](http://inf.ufrgs.br/%7Eeslgastal/SharedMatting/)

## Setups && Run
***Note: all JS are written in ES6 standard***
1. A modern browser
2. turn on webgl. for new version chrome, it is automatically enabled.
3. Copy code into your project along with all the shaders and `shared.js`

```js
let canvas = document.getElementById(YourCanvasID);
let runner = new SharedGL(canvas);
runner.setImage(ImageURL);
runner.setTrimap(TrimapURL);

// getScale is in the utils.js file
// image is the input image for matting
// scale is used to draw a centered result on canvas
let scale = utils.getScale(canvas.width, canvas.height, image.naturalWidth, image.naturalHeight);

// will draw the result to canvas
runner.run(scale);
```

## Demo

http://kingfolk.github.io/projects/shared_matting_webgl#projectDemo
