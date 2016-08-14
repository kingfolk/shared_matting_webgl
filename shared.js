import Igloo from 'igloo-ext';

import quadSL from './shaders/quad.vert.glsl';
import drawSL from './shaders/drawCanvas.frag.glsl';
import expandKnownSL from './shaders/expandKnown.frag.glsl';
import gatheringSL from './shaders/gathering.frag.glsl';
import refinementSL from './shaders/refinement.frag.glsl';
import localSmoothSL from './shaders/localSmooth.frag.glsl';

export default class Shared {
  constructor(canvas) {
    this.viewSize = new Float32Array([canvas.width, canvas.height]);
    this.igloo = new Igloo(canvas);
    let gl = this.gl = this.igloo.gl;
    let ext = this.ext = gl.getExtension('WEBGL_draw_buffers');
    if (!gl) {
      alert('Could not initialize WebGL!');
      throw new Error('No WebGL');
    }
    if (!ext) {
      alert('Could not initialize WebGL Ext!');
      throw new Error('No WEBGL_draw_buffers');
    }
    gl.disable(gl.DEPTH_TEST);

    this.textures = this.textures || {};
  }
  setImage(oriUrl) {
    this.loadImage(oriUrl, (img) => {
      let gl = this.gl;
      this.textures.ori = this.igloo.texture(img, gl.RGBA, gl.CLAMP_TO_EDGE, gl.NEAREST)
      this.stateSize = new Float32Array([img.naturalWidth, img.naturalHeight]);
      let maxPixels = 640000;
      if (this.stateSize[0] * this.stateSize[1] > maxPixels) {
        let ratio = Math.sqrt(maxPixels / (this.stateSize[0] * this.stateSize[1]) );
        this.stateSize[0] = ratio * this.stateSize[0];
        this.stateSize[1] = ratio * this.stateSize[1];
      }
    })
  }
  setTrimap(triUrl) {
    this.loadImage(triUrl, (img) => {
      let gl = this.gl;
      this.textures.tri = this.igloo.texture(img, gl.RGBA, gl.CLAMP_TO_EDGE, gl.NEAREST);
    })
  }
  glslSetup() {
    let igloo = this.igloo,
      gl = this.gl;

    this.framebuffers = {
      back: igloo.framebuffer(),
      refine: igloo.framebuffer(),
    };
    this.params = {
      kI: 10.0,
      kC: 5.0 / 255.0,
      kG: 4,
      searchRange: 500.0
    }

    this.programs = {
      copy: igloo.program(quadSL, drawSL),
      expandKnown: igloo.program(quadSL, expandKnownSL,
                  this.replacer({kI: this.params.kI})),
      gathering: igloo.program(quadSL, gatheringSL,
                  this.replacer({kG: this.params.kG, searchRange: this.params.searchRange})),
      refinement: igloo.program(quadSL, refinementSL),
      localSmooth: igloo.program(quadSL, localSmoothSL)
    };
    this.buffers = {
      quad: igloo.array(Igloo.QUAD2)
    };
    this.textures = {
      ...this.textures,
      triExpand: this.igloo.texture(null, gl.RGBA, gl.CLAMP_TO_EDGE, gl.NEAREST)
          .blank(this.stateSize[0], this.stateSize[1]),
      gatherFB: this.igloo.texture(null, gl.RGBA, gl.CLAMP_TO_EDGE, gl.NEAREST)
          .blank(this.stateSize[0], this.stateSize[1]),
      gatherFBSigma: this.igloo.texture(null, gl.RGBA, gl.CLAMP_TO_EDGE, gl.NEAREST)
          .blank(this.stateSize[0], this.stateSize[1]),
      refineF: this.igloo.texture(null, gl.RGBA, gl.CLAMP_TO_EDGE, gl.NEAREST)
          .blank(this.stateSize[0], this.stateSize[1]),
      refineB: this.igloo.texture(null, gl.RGBA, gl.CLAMP_TO_EDGE, gl.NEAREST)
          .blank(this.stateSize[0], this.stateSize[1]),
      refineAC: this.igloo.texture(null, gl.RGBA, gl.CLAMP_TO_EDGE, gl.NEAREST)
          .blank(this.stateSize[0], this.stateSize[1]),
      alpha: this.igloo.texture(null, gl.RGBA, gl.CLAMP_TO_EDGE, gl.NEAREST)
          .blank(this.stateSize[0], this.stateSize[1])
    }
  }
  run(canvasScale) {
    console.log('run shared matting')
    if (!this.textures.ori || !this.textures.tri) return;

    var t1 = new Date();
    this.glslSetup();
    var t2 = new Date();
    this
      .expandKnown()
      .gathering()
      .refinement()
      .localSmooth()
      .draw(canvasScale);
    var t3 = new Date();
    console.log(`Setup time: ${t2.getTime() - t1.getTime()}`)
    console.log(`Render time: ${t3.getTime() - t2.getTime()}`)
  }
  expandKnown() {
    let gl = this.gl;
    this.framebuffers.back.attach(this.textures.triExpand);
    this.textures.ori.bind(0);
    this.textures.tri.bind(1);
    // this.textures.triTest.bind(1);
    gl.viewport(0, 0, this.stateSize[0], this.stateSize[1]);

    this.programs.expandKnown.use()
      .attrib('quad', this.buffers.quad, 2)
      .uniformi('oriState', 0)
      .uniformi('triState', 1)
      .uniform('kC', this.params.kC)
      .uniform('scale', this.stateSize)
      .draw(gl.TRIANGLE_STRIP, 4);

    return this;
  }
  gathering(mode) {
    let gl = this.gl;

    if (mode == 'test') {
      this.framebuffers.back.attach(this.textures.alpha);
    }
    else {
      this.framebuffers.back.attach(this.textures.gatherFB);
    }
    if (gl.checkFramebufferStatus(gl.FRAMEBUFFER) !== gl.FRAMEBUFFER_COMPLETE) {
      alert('Could not initialize Buffer array!');
      throw new Error('No WebGL');
    }

    this.textures.ori.bind(0);
    // this.textures.triExpand.bind(1);
    this.textures.triExpand.bind(1);
    gl.viewport(0, 0, this.stateSize[0], this.stateSize[1]);

    this.programs.gathering.use()
      .attrib('quad', this.buffers.quad, 2)
      .uniformi('oriState', 0)
      .uniformi('triState', 1)
      .uniformi('isTest', mode == 'test' ? 1 : 0)
      .uniformi('kG', this.params.kG)
      .uniform('scale', this.stateSize)
      .draw(gl.TRIANGLE_STRIP, 4);

    return this;
  }
  refinement(mode) {
    let gl = this.gl;
    let arr = [];
    if (mode == 'test') { arr = [this.textures.alpha]; }
    else { arr = [this.textures.refineF, this.textures.refineB, this.textures.refineAC]; }

    this.framebuffers.refine.attachArr(arr);
    if (gl.checkFramebufferStatus(gl.FRAMEBUFFER) !== gl.FRAMEBUFFER_COMPLETE) {
      alert('Could not initialize Buffer array!');
      throw new Error('No WebGL');
    }
    this.textures.ori.bind(0);
    // this.textures.triExpand.bind(1);
    this.textures.triExpand.bind(1);
    this.textures.gatherFB.bind(2);
    this.textures.gatherFBSigma.bind(3);
    gl.viewport(0, 0, this.stateSize[0], this.stateSize[1]);

    this.programs.refinement.use()
      .attrib('quad', this.buffers.quad, 2)
      .uniformi('oriState', 0)
      .uniformi('triState', 1)
      .uniformi('fbState', 2)
      .uniformi('fbSigmaState', 3)
      .uniformi('isTest', mode == 'test' ? 1 : 0)
      .uniform('scale', this.stateSize)
      .draw(gl.TRIANGLE_STRIP, 4);

    return this;
  }
  localSmooth() {
    let gl = this.gl;
    this.framebuffers.back.attach(this.textures.alpha);

    this.textures.ori.bind(0);
    // this.textures.triExpand.bind(1);
    this.textures.triExpand.bind(1);
    this.textures.refineAC.bind(2);
    this.textures.refineF.bind(3);
    this.textures.refineB.bind(4);
    gl.viewport(0, 0, this.stateSize[0], this.stateSize[1]);

    this.programs.localSmooth.use()
      .attrib('quad', this.buffers.quad, 2)
      .uniformi('oriState', 0)
      .uniformi('triState', 1)
      .uniformi('acState', 2)
      .uniformi('foreState', 3)
      .uniformi('backState', 4)
      .uniform('scale', this.stateSize)
      .draw(gl.TRIANGLE_STRIP, 4);

    return this;
  }
  draw(canvasScale) {
    let gl = this.gl;
    this.igloo.defaultFramebuffer.bind();
    this.textures.alpha.bind(0);
    gl.viewport(0, 0, this.viewSize[0], this.viewSize[1]);

    let offset = new Float32Array([canvasScale.ol, canvasScale.ot]);
    this.programs.copy.use()
      .attrib('quad', this.buffers.quad, 2)
      .uniformi('state', 0)
      .uniform('scale', this.viewSize)
      .uniform('offset', offset)
      .draw(gl.TRIANGLE_STRIP, 4);

    return this;
  }

  replacer(map) {
    var keys = Object.keys(map);
    return function(source) {
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i], regex = new RegExp('%%' + key + '%%', 'g');
            source = source.replace(regex, map[key]);
        }
        return source;
    };
  }

  loadImage(image, callback) {
    let img = image;
    if (typeof img === 'string') {
      img = new Image();
      img.src = image;
    }
    img.onload = () => {
      img.style.display = 'none';
      if (callback) {
        callback(img);
      }
    }
  }
}
