export default {
  name: 'element',
  props: ['name', 'nature', 'value'],
  methods: {
    change(ev) {
      this.$emit('update:value', {
        Name: this.name,
        Nature: this.nature,
        Value: +ev.target.value,
      });
    },
  },
};
