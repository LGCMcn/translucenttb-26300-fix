import React from "react";
import { Composition } from "remotion";
import { TTBFixVideo } from "./Video";
import { CoverA, CoverB, CoverC } from "./Cover";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="TTBFix"
        component={TTBFixVideo}
        durationInFrames={3084}
        fps={30}
        width={1920}
        height={1080}
      />
      <Composition id="CoverA" component={CoverA} durationInFrames={1} fps={30} width={1920} height={1080} />
      <Composition id="CoverB" component={CoverB} durationInFrames={1} fps={30} width={1920} height={1080} />
      <Composition id="CoverC" component={CoverC} durationInFrames={1} fps={30} width={1920} height={1080} />
    </>
  );
};
