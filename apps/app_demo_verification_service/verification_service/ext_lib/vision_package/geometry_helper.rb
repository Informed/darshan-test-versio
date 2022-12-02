module VisionPackage
  module GeometryHelper
    include Geometry

    def self.included(base)
      base.extend(Geometry)
    end
  end
end
