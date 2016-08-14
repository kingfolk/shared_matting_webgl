function getScale(cw, ch, iw, ih) {
  let ot, ol, iw_, ih_, ratio;
  if (iw / ih > cw / ch) {
    ratio = cw / iw;
    iw_ = iw * ratio;
    ih_ = ih * ratio;
    ot = (ch - ih_) / 2;
    ol = 0;
  }
  else {
    ratio = ch / ih;
    iw_ = iw * ratio;
    ih_ = ih * ratio;
    ot = 0;
    ol = (cw - iw_) / 2;
  }
  return {
    ot,
    ol,
    iw: iw_,
    ih: ih_,
  }
}

export {getScale};
