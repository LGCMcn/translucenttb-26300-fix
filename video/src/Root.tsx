import React from "react";
import { Composition } from "remotion";
import { TTBFixVideo } from "./Video";

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
    </>
  );
};
