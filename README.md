# Library for automatically genereating ffi-bindings for c/c++ libraries'

Rbind is developed to automatically generate ruby bindings for OpenCV but is
not tight to this library. It allows to import already wrapped types from other
gems/libraries using rbind to share the same types across multiple
gems/libraries. For now rbind uses a copy of the OpenCV python hdr parser to
parse c/c++ header files and looks for certain defines.  This gem is still
under heavy development and the API might change in the future.

## Features:
- inheritance
- method overloading
- default values
- argument annotation
- type sharing across libraries
- gem support

## TODO:
- add documentation
- add unit test especially for string normalization
- move to clang
- make parser more robust (empty lines will produce an error)
- proper error if name of a argument is missing
- add better support for type specializing on the ruby side 
- add support for yard
- use directly type lib types as inter-media types (optional)
- check that all functions have a return value or are constructors
- add alias for the original c++ method names
- make ruby/lib configurable
- support for changing ownership (add special flag)

## Defines which are picked up from the c++ header files
- CV_EXPORTS_W CV_EXPORTS
- CV_EXPORTS_W_SIMPLE CV_EXPORTS
- CV_EXPORTS_AS(synonym) CV_EXPORTS
- CV_EXPORTS_W_MAP CV_EXPORTS
- CV_IN_OUT
- CV_OUT
- CV_PROP
- CV_PROP_RW
- CV_WRAP
- CV_WRAP_AS(synonym)
- CV_WRAP_DEFAULT(value)

# Example1 (ropencv)
## file rbind.rb

    require 'rbind'
    rbind = Rbind::Rbind.new("OpenCV")

    # add dependency to opencv
    rbind.pkg_config << "opencv"

    #add opencv headers
    rbind.includes =   ["opencv2/core/core_c.h", "opencv2/core/types_c.h",
                        "opencv2/core/core.hpp", "opencv2/flann/miniflann.hpp",
                        "opencv2/imgproc/imgproc_c.h", "opencv2/imgproc/types_c.h",
                        "opencv2/imgproc/imgproc.hpp", "opencv2/photo/photo_c.h",
                        "opencv2/photo/photo.hpp", "opencv2/video/video.hpp",
                        "opencv2/features2d/features2d.hpp", "opencv2/objdetect/objdetect.hpp",
                        "opencv2/calib3d/calib3d.hpp", "opencv2/ml/ml.hpp",
                        "opencv2/highgui/highgui_c.h", "opencv2/highgui/highgui.hpp",
                        "opencv2/contrib/contrib.hpp", "opencv2/nonfree/nonfree.hpp",
                        "opencv2/nonfree/features2d.hpp"]

    # auto add vector and ptr types
    rbind.on_type_not_found do |owner,type|
        if type =~ /Ptr_(.*)/
            t = rbind.parser.find_type(owner,$1)
            t2 = Rbind::RPtr.new(type,rbind,t).typedef("cv::Ptr<#{t.full_name} >")
            rbind.parser.add_type t2
        elsif type =~ /vector_(.*)/
            t = rbind.parser.find_type(owner,$1)
            t2 = Rbind::RVector.new(type,rbind,t).typedef("std::vector<#{t.full_name} >")
            rbind.parser.add_type t2
        end
    end

    # parse type definitions
    rbind.parse File.join(File.dirname(__FILE__),"pre_opencv244.txt")
    rbind.parse File.join(File.dirname(__FILE__),"opencv.txt")

    # using namespace cv (cv::Mat can now be addressed as Mat)
    rbind.use_namespace rbind.cv

    # alias a type 
    rbind.cv.types_alias["string"] = rbind.cv.String

    # parse headers
    rbind.parse_headers

    # fix some errors because of missing defines in the c++ headers
    rbind.cv.putText.parameter(0).add_flag(:IO)
    rbind.cv.chamerMatching.parameter(0).add_flag(:IO)
    rbind.cv.chamerMatching.parameter(1).add_flag(:IO)
    rbind.cv.chamerMatching.parameter(2).add_flag(:IO)

    # add some more vector types
    rbind.parser.find_type(rbind,"vector_Point3f")
    rbind.parser.find_type(rbind,"vector_Point3d")

    # generate files
    rbind.generator_ruby.file_prefix = "ropencv"
    rbind.generate(File.join(File.dirname(__FILE__),"src"),File.join(File.dirname(__FILE__),"..","lib","ruby","ropencv"))


# Example2
## file rbind.rb
    require 'rbind'
    rbind = Rbind::Rbind.new("FrameHelper")

    # add pkg config dependency
    rbind.pkg_config << "base-types"

    # add dependency to ruby bindings for opencv
    rbind.gems << "ropencv"

    # add headers which shall be parsed
    rbind.includes = [File.absolute_path(File.join(File.dirname(__FILE__),"..","..","src","FrameHelperTypes.h")),
                      File.absolute_path(File.join(File.dirname(__FILE__),"..","..","src","FrameHelper.h"))]

    # parse additional file specifying some types
    rbind.parse File.join(File.dirname(__FILE__),"types.txt")

    # parse types exported by the gem ropencv
    rbind.parse_extern

    # using namespace cv (cv::Mat can now be addressed as Mat)
    rbind.use_namespace rbind.cv

    # parse headers
    rbind.parse_headers

    # add additional target to the linker
    rbind.libs << "frame_helper"

    # generate all files
    rbind.generate(File.join(File.dirname(__FILE__),"src"),File.join(File.dirname(__FILE__),"lib","ruby","frame_helper"))

## file types.txt
    struct base.samples.frame.Frame
    base.samples.frame.Frame.Frame

## file FrameHelper.h
    class CV_EXPORTS_W FrameHelper
    {
        ...
        public:
            CV_WRAP FrameHelper();
            CV_WRAP void convert(const base::samples::frame::Frame &src,CV_OUT base::samples::frame::Frame &dst,
                    int offset_x = 0, int offset_y = 0, int algo = INTER_LINEAR, bool bundistort=false);
        ...
    }

## file ruby_test.rb
   require 'frame_helper'
   f = FrameHelper::FrameHelper.new
   f.convert(...)

