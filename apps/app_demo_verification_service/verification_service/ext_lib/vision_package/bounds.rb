module VisionPackage
  class Bounds
    include GeometryHelper
    attr_accessor :points, :polygon

    class << self
      def factory(bounds)
        bounds.is_a?(Bounds) ? bounds : Bounds.new(bounds)
      end

      def line(pt1, pt2)
        Line.new(point(pt1), point(pt2))
      end

      def point(pt)
        return pt if pt.is_a?(Point)
        pt.is_a?(Array) ? Point.new(*pt) : Point.new(pt.fetch('x', 0), pt.fetch('y', 0))
      end

      def slope(point1, point2, default_zero = true)
        point1, point2 = [point1, point2].map { |pt| point(pt) }
        return Float::INFINITY if point1.x == point2.x && !default_zero
        (point2.y - point1.y).fdiv(point1.x == point2.x ? 0.1 : point2.x - point1.x)
      end

      def find_x_on_a_line(point1, point2, y)
        point1, point2 = [point1, point2].map { |pt| point(pt) }
        m = slope(point1, point2, false)
        (y - point2.y).div(m) + point1.x unless m.zero? || m.infinite?
      end

      def find_y_on_a_line(point1, point2, x)
        point1, point2 = [point1, point2].map { |pt| point(pt) }
        m = slope(point1, point2, false)
        (m * (x - point2.x)) + point2.y unless m.zero? || m.infinite?
      end

      def within_range?(range1, range2, tolerance)
        ((range2.min - tolerance)..(range2.max + tolerance)).overlaps?(range1)
      end

      def intersection_percent(range1, range2)
        ([range1.max, range2.max].min - [range1.min, range2.min].max).fdiv(range1.max - range1.min) * 100
      end

      def area(bounds)
        (bounds.max_x - bounds.min_x).abs * (bounds.max_y - bounds.min_y).abs
      end

      def area_overlap(bounds1, bounds2, options = {})
        padding = options.fetch(:padding, 0.0)

        min_x = [bounds1.min_x, bounds2.min_x].max
        max_x = [bounds1.max_x, bounds2.max_x].min
        min_y = [bounds1.min_y, bounds2.min_y].max
        max_y = [bounds1.max_y, bounds2.max_y].min
        width = ((max_x - min_x) * (1.0 + padding)).floor
        height = ((max_y - min_y) * (1.0 + padding)).floor
        return 0 if [width, height].any?(&:negative?)
        width * height
      end

      def area_overlap?(bounds1, bounds2, options = {})
        padding = options.fetch(:padding, 0.0)
        min_intersection = options.fetch(:min_intersection, 0.7)

        max_area = [bounds1.area, bounds2.area].max
        area_overlap(bounds1, bounds2, padding: padding).fdiv(max_area) >= min_intersection
      end

      def overlap_bounds(bounds1, bounds2, options = {})
        paddding = options.fetch(:paddding, 0)

        bounds1, bounds2 = [bounds1, bounds2].sort_by(&:min_x)
        x1 = [bounds1.min_x, bounds2.min_x].max
        x2 = [bounds1.max_x, bounds2.max_x].min
        y1 = [bounds1.min_y, bounds2.min_y].max - paddding
        y2 = [bounds1.max_y, bounds2.max_y].min + paddding
        Bounds.factory([[x1, y1], [x2, y1], [x2, y2], [x1, y2]])
      end

      def from_section(section)
        x1, y1, x2, y2 = section
        Bounds.factory([[x1, y1], [x2, y1], [x2, y2], [x1, y2]])
      end

      def from_displacing_bounds(bounds, options = {})
        x_values = options.fetch(:x_values, nil)
        y_values = options.fetch(:y_values, nil)

        x1, x2 = (x_values.is_a?(Array) ? x_values : [x_values] * 2).map(&:to_i)
        y1, y2 = (y_values.is_a?(Array) ? y_values : [y_values] * 2).map(&:to_i)
        Bounds.factory([
                         [bounds.top_left.x + x1, bounds.top_left.y + y1],
                         [bounds.top_right.x + x2, bounds.top_right.y + y1],
                         [bounds.bottom_right.x + x2, bounds.bottom_right.y + y2],
                         [bounds.bottom_left.x + x1, bounds.bottom_left.y + y2]
                       ])
      end

      def section_in_same_row(bounds, left_x, right_x, threshold = 1)
        top_y = bounds.min_y - bounds.font_height.fdiv(threshold)
        bottom_y = bounds.max_y + bounds.font_height.fdiv(threshold)
        Bounds.new([[left_x, top_y], [right_x, top_y], [right_x, bottom_y], [left_x, bottom_y]])
      end

      def section_in_same_col(bounds, top_y, bottom_y, threshold = 1)
        left_x = bounds.min_x - (0.5 * bounds.font_width.fdiv(threshold))
        right_x = bounds.max_x + (0.5 * bounds.font_width.fdiv(threshold))
        Bounds.new([[left_x, top_y], [right_x, top_y], [right_x, bottom_y], [left_x, bottom_y]])
      end

      def from_crop_params(crop_data)
        top, left, width, height = crop_data.with_indifferent_access.values_at('top', 'left', 'width', 'height')
        from_section([left, top, left + width, top + height])
      end
    end

    def deep_clone
      Bounds.factory([
                       [top_left.x, top_left.y],
                       [top_right.x, top_right.y],
                       [bottom_right.x, bottom_right.y],
                       [bottom_left.x, bottom_left.y]
                     ])
    end

    def to_points
      [
        [min_x, min_y],
        [max_x, min_y],
        [max_x, max_y],
        [min_x, max_y]
      ]
    end

    def top_slope
      Bounds.slope(top_left, top_right)
    end

    def top_max_y
      [top_left.y, top_right.y].max
    end

    # finding the slope on the word itself (top_left against bottom_left)
    def word_vertical_slope
      left_slope = Bounds.slope(top_left, bottom_left, false)
      right_slope = Bounds.slope(top_right, bottom_right, false)
      return 0 if left_slope == Float::INFINITY && right_slope == Float::INFINITY
      return 1 / left_slope if right_slope == Float::INFINITY
      return 1 / right_slope if left_slope == Float::INFINITY
      slope = [1 / left_slope, 1 / right_slope].max_by(&:abs)
      slope.finite? ? slope : 0
    end

    def initialize(bounds)
      @points = bounds.map { |bound| Bounds.point(bound) }
      @polygon = Polygon(points)
    end

    def centroid
      @centroid ||= Point.new(x_coords.sum.fdiv(points.length), y_coords.sum.fdiv(points.length))
    end

    def distance_to(bounds)
      centroid.distance_to(bounds.centroid)
    end

    def y_distance(bounds)
      top, bottom = [self, bounds].sort_by(&:min_y)
      bottom.min_y - top.max_y
    end

    def x_distance(bounds)
      left, right = [self, bounds].sort_by(&:min_x)
      right.min_x - left.max_x
    end

    def close_to?(bounds, options = {})
      x_threshold = options.fetch(:x_threshold, 90)
      y_threshold = options.fetch(:y_threshold, 90)
      return y_distance(bounds).abs < y_threshold if bounds.intersects_vertically?(self)
      return x_distance(bounds).abs < x_threshold if bounds.intersects_horizontally?(self)
      false
    end

    def default_horizontal_tolerance
      (max_y - min_y).fdiv(2)
    end

    def default_vertical_tolerance
      (max_x - min_x).fdiv(2)
    end

    def connected_horizontally?(bounds, tolerance = nil)
      (centroid.y - bounds.centroid.y).abs <= (tolerance || default_horizontal_tolerance)
    end

    def connected_vertically?(bounds, tolerance = nil)
      (centroid.x - bounds.centroid.x).abs <= (tolerance || default_vertical_tolerance)
    end

    def connected_on_slope?(bounds, tolerance = nil, strict = false)
      left, right = max_x > bounds.max_x ? [bounds, self] : [self, bounds]
      # check each word to see if itself is strict rectangle
      left_word_slope = left.word_vertical_slope
      right_word_slope = right.word_vertical_slope
      average_slope = [left_word_slope, right_word_slope].max_by(&:abs)
      point1 = left.bottom_right
      point2 = right.bottom_right
      font_height = right.max_y - right.min_y
      # if two words are far enough on width, give extra allowance on the slope
      word_width = [left.width, right.width].max.zero? ? 1 : [left.width, right.width].max
      slope_allowance = !strict && (right.max_x - left.max_x) / word_width > 4 ? 1.5 : 1
      tolerance ||= Bounds.slope(point1, Point.new(point2.x, point1.y + (slope_allowance * font_height.fdiv(2)))).abs
      return Bounds.slope(point1, point2).abs <= tolerance if average_slope.abs < 0.1
      (average_slope * Bounds.slope(point1, point2)).negative? && Bounds.slope(point1, point2).abs <= tolerance
    end

    def connected?(bounds, tolerance = nil)
      connected_horizontally?(bounds, tolerance) || connected_vertically?(bounds, tolerance) ||
        connected_on_slope?(bounds, tolerance)
    end

    def close?(bounds, line_height = 3.5)
      distance_to(bounds) < font_height * line_height
    end

    def connected_and_close?(bounds)
      connected?(bounds) && close?(bounds)
    end

    def horizontal_intersection_params(bounds)
      if top_slope.abs > 0.04
        y1 = Bounds.find_y_on_a_line(top_left, top_right, bounds.top_left.x)
        y2 = Bounds.find_y_on_a_line(bottom_left, bottom_right, bounds.bottom_left.x)
        return [nil] * 2 unless [y1, y2].all?
      end
      range = [y1, y2].all? ? [y1, y2].min.floor..[y1, y2].max.ceil : range_y
      [range, bounds.range_y]
    end

    def vertical_intersection_params(bounds)
      x1 = Bounds.find_x_on_a_line(top_left, bottom_left, bounds.top_left.y)
      x2 = Bounds.find_x_on_a_line(top_right, bottom_right, bounds.top_right.y)
      range = [x1, x2].all? ? [x1, x2].min.floor..[x1, x2].max.ceil : range_x
      [range, bounds.range_x]
    end

    def intersects_horizontally?(bounds, tolerance = nil)
      tolerance ||= 0
      return bounds.in_horizontal_intersection_range?(self, tolerance) if top_slope.zero? && !bounds.top_slope.zero?
      return in_horizontal_intersection_range?(bounds, tolerance) if !top_slope.zero? && bounds.top_slope.zero?
      bounds.in_horizontal_intersection_range?(self, tolerance) && in_horizontal_intersection_range?(bounds, tolerance)
    end

    def in_horizontal_intersection_range?(bounds, tolerance)
      range1, range2 = horizontal_intersection_params(bounds)
      return false unless [range1, range2].all?
      Bounds.within_range?(range1, range2, tolerance) || Bounds.within_range?(range2, range1, tolerance)
    end

    def intersects_vertically?(bounds, tolerance = nil)
      tolerance ||= 10
      range1, range2 = vertical_intersection_params(bounds)
      Bounds.within_range?(range1, range2, tolerance) || Bounds.within_range?(range2, range1, tolerance)
    end

    def horizontal_intersection_percent(bounds)
      return Bounds.intersection_percent(*horizontal_intersection_params(bounds)) if intersects_horizontally?(bounds)
      Bounds.intersection_percent(*bounds.horizontal_intersection_params(self)) if bounds.intersects_horizontally?(self)
    end

    def vertical_intersection_percent(bounds)
      return Bounds.intersection_percent(*vertical_intersection_params(bounds)) if intersects_vertically?(bounds)
      Bounds.intersection_percent(*bounds.vertical_intersection_params(self)) if bounds.intersects_vertically?(self)
    end

    def relative_position(bounds)
      positions = []
      y_diff = top_left.y - bounds.top_left.y
      x_diff = top_left.x - bounds.top_left.x
      positions.push(y_diff.positive? ? :top : :bottom) unless y_diff.zero?
      positions.push(x_diff.positive? ? :left : :right) unless x_diff.zero?
      positions
    end

    def intersects_left?(bounds, tolerance = nil)
      intersects_horizontally?(bounds, tolerance) && relative_position(bounds).include?(:left)
    end

    def intersects_right?(bounds, tolerance = nil)
      intersects_horizontally?(bounds, tolerance) && relative_position(bounds).include?(:right)
    end

    def intersects_top?(bounds, tolerance = nil)
      intersects_vertically?(bounds, tolerance) && relative_position(bounds).include?(:top)
    end

    def intersects_bottom?(bounds, tolerance = nil)
      intersects_vertically?(bounds, tolerance) && relative_position(bounds).include?(:bottom)
    end

    def angle
      @angle ||= atan2(top_left.y - top_right.y, top_right.x - top_left.x) * 180.div(PI)
    end

    def rotated?(range = nil)
      (range || (85..95)).cover?(angle.abs)
    end

    def height
      min, max = minmax_y
      max - min
    end

    alias font_height height

    def width
      min, max = minmax_x
      max - min
    end

    def dimensions
      { 'height' => height, 'width' => width }
    end

    def area
      Bounds.area(self)
    end

    def add_y_offset(offset)
      points.each { |pt| pt.y += offset }
      # these need to be reset because they are cached == big big problems!
      @minmax_y = nil
      @y_coords = nil
    end

    def contains?(bounds)
      polygon.contains?(bounds.top_left) || polygon.contains?(bounds.top_right) ||
        polygon.contains?(bounds.bottom_left) || polygon.contains?(bounds.bottom_right)
    end

    def strictly_contains?(bounds, num = 2)
      bounds.points.select { |a| polygon.contains?(a) }.length > num
    end

    def contains_centroid?(bounds)
      polygon.contains?(bounds.centroid)
    end

    def contains_point?(point)
      point.x.between?(range_x) && point.y.between?(range_y)
    end

    def above?(bounds)
      max_y <= (bounds.min_y + (font_height / 3))
    end

    def strictly_above?(bounds)
      max_y < bounds.min_y
    end

    alias top? above?

    def bottom?(bounds)
      min_y >= bounds.max_y
    end

    def left?(bounds)
      max_x <= bounds.min_x
    end

    def right?(bounds)
      min_x >= bounds.max_x
    end

    def minmax
      [minmax_x, minmax_y]
    end

    def minmax_x
      @minmax_x ||= x_coords.minmax
    end

    def min_x
      minmax_x.first
    end

    def max_x
      minmax_x.last
    end

    def range_x
      min_x..max_x
    end

    def minmax_y
      @minmax_y ||= y_coords.minmax
    end

    def min_y
      minmax_y.first
    end

    def max_y
      minmax_y.last
    end

    def range_y
      min_y..max_y
    end

    def x_coords
      @x_coords ||= points.map(&:x)
    end

    def y_coords
      @y_coords ||= points.map(&:y)
    end

    def top_left
      points.first
    end

    def top_right
      points.second
    end

    def bottom_right
      points.third
    end

    def bottom_left
      points.last
    end

    def to_h
      points.map { |pt| pt.to_h.with_indifferent_access }
    end

    def to_payload
      {
        'points'              => to_h,
        'min_x'               => min_x,
        'max_x'               => max_x,
        'min_y'               => min_y,
        'max_y'               => max_y,
        'top_slope'           => top_slope,
        'word_vertical_slope' => word_vertical_slope,
        'centroid'            => centroid.to_h,
        'angle'               => angle
      }
    end

    alias inspect to_h
  end
end
