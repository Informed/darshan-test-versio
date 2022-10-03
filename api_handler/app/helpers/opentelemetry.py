from opentelemetry import trace
from opentelemetry.trace import format_span_id, format_trace_id


class Opentelemetry:
    def traceparent(self):
        current_span_context = trace.get_current_span().get_span_context()
        traceparent = "00-{trace_id}-{span_id}-0{trace_flag}"

        return traceparent.format(
            trace_id=format_trace_id(current_span_context.trace_id),
            span_id=format_span_id(current_span_context.span_id),
            trace_flag=current_span_context.trace_flags
        )
