//
//  VideoFrame.h
//  iSeen
//
//  Created by Ling Evan on 25/12/15.
//  Copyright © 2015 Evan. All rights reserved.
//

#ifndef VideoFrame_h
#define VideoFrame_h

#include <cstddef>

struct VideoFrame
{
    size_t width;
    size_t height;
    size_t stride;
    
    unsigned char * data;
};


#endif /* VideoFrame_h */
